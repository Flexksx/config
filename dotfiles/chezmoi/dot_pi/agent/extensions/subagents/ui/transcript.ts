import {
	type AgentSession,
	AssistantMessageComponent,
	getMarkdownTheme,
	ToolExecutionComponent,
	UserMessageComponent,
} from "@earendil-works/pi-coding-agent";
import { Container, type TUI } from "@earendil-works/pi-tui";
import { rowRenderers } from "./renderer-capture.ts";

export class Transcript {
	readonly container = new Container();
	private readonly tools = new Map<string, ToolExecutionComponent>();
	private streaming?: AssistantMessageComponent;
	private expanded = false;
	private readonly markdown = getMarkdownTheme();

	constructor(
		private readonly tui: TUI,
		private readonly session: AgentSession,
		private readonly cwd: string,
	) {
		for (const message of session.messages) this.add(message);
	}

	toggleExpanded(): void {
		this.expanded = !this.expanded;
		for (const tool of this.tools.values()) tool.setExpanded(this.expanded);
	}

	private add(message: AgentSession["messages"][number]): void {
		if (message.role === "user") {
			const text = typeof message.content === "string" ? message.content : textOf(message.content);
			this.container.addChild(new UserMessageComponent(text, this.markdown));
		} else if (message.role === "assistant") {
			this.container.addChild(new AssistantMessageComponent(message, true, this.markdown));
			this.addToolCalls(message);
		} else if (message.role === "toolResult") {
			this.tools.get(message.toolCallId)?.updateResult({
				content: message.content,
				details: message.details,
				isError: message.isError,
			});
		}
	}

	private addToolCalls(message: Extract<AgentSession["messages"][number], { role: "assistant" }>): void {
		for (const block of message.content) {
			if (block.type !== "toolCall" || this.tools.has(block.id)) continue;
			const row = new ToolExecutionComponent(
				block.name,
				block.id,
				block.arguments,
				{},
				rowRenderers(block.name, this.session.getToolDefinition(block.name)),
				this.tui,
				this.cwd,
			);
			row.setArgsComplete();
			row.setExpanded(this.expanded);
			this.tools.set(block.id, row);
			this.container.addChild(row);
		}
	}

	handle(event: Parameters<Parameters<AgentSession["subscribe"]>[0]>[0]): void {
		if (event.type === "message_update" && event.message.role === "assistant") {
			if (!this.streaming) {
				this.streaming = new AssistantMessageComponent(undefined, true, this.markdown);
				this.container.addChild(this.streaming);
			}
			this.streaming.updateContent(event.message, true);
		} else if (event.type === "message_end") {
			if (event.message.role === "assistant") {
				if (this.streaming) this.streaming.updateContent(event.message, false);
				else this.container.addChild(new AssistantMessageComponent(event.message, true, this.markdown));
				this.streaming = undefined;
				this.addToolCalls(event.message);
			} else if (event.message.role === "user") {
				this.add(event.message);
			}
		} else if (event.type === "tool_execution_start") {
			this.tools.get(event.toolCallId)?.markExecutionStarted();
		} else if (event.type === "tool_execution_update") {
			this.tools.get(event.toolCallId)?.updateResult({ ...event.partialResult, isError: false }, true);
		} else if (event.type === "tool_execution_end") {
			this.tools.get(event.toolCallId)?.updateResult({
				...event.result,
				isError: event.isError,
				durationMs: event.durationMs,
			});
		}
	}
}

function textOf(content: readonly { type: string; text?: string }[]): string {
	return content
		.filter((b) => b.type === "text")
		.map((b) => b.text ?? "")
		.join("\n");
}
