import { defineTool, type ToolDefinition } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import type { SubagentManager } from "../manager.ts";
import { TOOL_NAMES } from "../protocol.ts";
import type { Run } from "../run.ts";

export function bridgeTools(run: Run, manager: SubagentManager): ToolDefinition[] {
	return [
		defineTool({
			name: TOOL_NAMES.message,
			label: "Message parent",
			description: "Send a one-way update to the parent agent. Returns at once.",
			parameters: Type.Object({ message: Type.String() }),
			async execute(_id, { message }) {
				manager.message(run, message);
				return {
					content: [{ type: "text", text: "Delivered to the parent." }],
					details: undefined,
				};
			},
		}),
		defineTool({
			name: TOOL_NAMES.ask,
			label: "Ask parent",
			description:
				"Ask the parent agent a question and wait for its answer. Use only when you cannot continue without it.",
			parameters: Type.Object({ question: Type.String() }),
			executionMode: "sequential",
			async execute(_id, { question }, signal) {
				const answer = await manager.ask(run, question, signal);
				return {
					content: [{ type: "text", text: answer }],
					details: undefined,
				};
			},
		}),
	];
}
