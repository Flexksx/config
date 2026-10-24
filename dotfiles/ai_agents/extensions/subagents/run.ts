import type { AgentSession } from "@earendil-works/pi-coding-agent";
import type { AgentDef } from "./agents.ts";
import { TOOL_NAMES } from "./protocol.ts";

export type RunStatus = "starting" | "running" | "waiting" | "done" | "failed" | "aborted";

export type Activity = "thinking" | "writing" | "read" | "edit" | "bash" | "search" | "web" | "bridge" | "tool";

export interface PendingAsk {
	question: string;
	resolve(answer: string): void;
}

export interface Interaction {
	by: "parent" | "user";
	kind: "reply" | "answer" | "steer" | "follow-up";
	text: string;
}

export type ForegroundOutcome = { kind: "settled" } | { kind: "ask"; question: string };

export class Run {
	status: RunStatus = "starting";
	activity: Activity = "thinking";
	lastToolActivity?: Activity;
	lastToolEndedAt = 0;
	session?: AgentSession;
	lastTool?: string;
	lastText?: string;
	error?: string;
	pendingAsk?: PendingAsk;
	foreground?: (outcome: ForegroundOutcome) => void;
	endedAt?: number;
	readonly interactions: Interaction[] = [];
	private reported = 0;
	private readonly listeners = new Set<() => void>();
	private streamedText = "";

	constructor(
		readonly id: string,
		readonly agent: AgentDef,
		readonly task: string,
		readonly cwd: string,
		readonly generation: number,
	) {}

	get active(): boolean {
		return this.status === "starting" || this.status === "running" || this.status === "waiting";
	}

	onChange(listener: () => void): () => void {
		this.listeners.add(listener);
		return () => this.listeners.delete(listener);
	}

	changed(): void {
		for (const listener of this.listeners) listener();
	}

	attach(session: AgentSession): void {
		this.session = session;
		session.subscribe((event) => {
			const update = event.type === "message_update" ? event.assistantMessageEvent : undefined;
			if (update?.type === "toolcall_start") {
				const block = update.partial.content[update.contentIndex];
				if (block?.type !== "toolCall" || !block.name) return;
				this.activity = activityOf(block.name);
				this.lastTool = `${block.name}: \u2026`;
			} else if (event.type === "tool_execution_start") {
				this.activity = activityOf(event.toolName);
				this.lastTool = `${event.toolName}: ${summarizeArgs(event.args)}`;
			} else if (event.type === "tool_execution_end") {
				this.lastToolActivity = this.activity;
				this.lastToolEndedAt = Date.now();
				this.activity = "thinking";
			} else if (event.type === "turn_start") {
				this.activity = "thinking";
			} else if (event.type === "message_start") {
				this.streamedText = "";
			} else if (event.type === "message_update" && event.assistantMessageEvent.type === "thinking_delta") {
				if (this.activity === "thinking") return;
				this.activity = "thinking";
			} else if (event.type === "message_update" && event.assistantMessageEvent.type === "text_delta") {
				this.activity = "writing";
				this.streamedText += event.assistantMessageEvent.delta;
				const line = this.streamedText
					.split("\n")
					.map((l) => l.trim())
					.findLast((l) => /\w/.test(l) && !l.startsWith("```"));
				if (line) this.lastText = line;
			} else {
				return;
			}
			this.changed();
		});
	}

	record(interaction: Interaction): void {
		this.interactions.push(interaction);
	}

	unreported(): Interaction[] {
		return this.interactions.slice(this.reported);
	}

	markReported(): void {
		this.reported = this.interactions.length;
	}

	stats(): { tokens: number; cost: number; model?: string } {
		const stats = this.session?.getSessionStats();
		return { tokens: stats?.tokens.total ?? 0, cost: stats?.cost ?? 0, model: this.session?.model?.id };
	}

	result(): string {
		return this.session?.getLastAssistantText()?.trim() || "(no output)";
	}
}

function activityOf(toolName: string): Activity {
	const name = toolName.toLowerCase();
	if (name === "read" || name === "ls") return "read";
	if (name === "edit" || name === "write") return "edit";
	if (name === "bash") return "bash";
	if (name === TOOL_NAMES.message || name === TOOL_NAMES.ask) return "bridge";
	if (name.includes("grep") || name.includes("find")) return "search";
	if (name.includes("web") || name.includes("fetch")) return "web";
	return "tool";
}

function summarizeArgs(args: unknown): string {
	if (!args || typeof args !== "object") return "";
	const record = args as Record<string, unknown>;
	const parts = ["command", "pattern", "query", "path", "url"]
		.map((key) => record[key])
		.filter((v): v is string => typeof v === "string" && v.trim() !== "");
	const text = parts.length > 0 ? parts.join(" ") : JSON.stringify(args);
	return text.replace(/\s+/g, " ").slice(0, 80);
}
