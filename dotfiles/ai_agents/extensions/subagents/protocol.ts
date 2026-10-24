import type { ToolDefinition } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

export const TOOL_NAMES = {
	spawn: "subagent",
	reply: "reply_to_subagent",
	message: "message_parent",
	ask: "ask_parent",
} as const;

export const MESSAGE_TYPES = {
	message: "subagent-message",
	ask: "subagent-ask",
	result: "subagent-result",
	interaction: "subagent-interaction",
} as const;

export type MessageType = (typeof MESSAGE_TYPES)[keyof typeof MESSAGE_TYPES];

export interface BridgeDetails {
	id: string;
	agent: string;
	text: string;
}

export interface SubagentDetails {
	id: string;
}

export const SubagentParams = Type.Object({
	agent: Type.String({ description: "Agent name" }),
	task: Type.String({ description: "Complete, self-contained task" }),
	background: Type.Optional(Type.Boolean({ description: "Return at once; the result arrives later as a message. Default false." })),
	model: Type.Optional(Type.String({ description: "provider/model-id for this call, e.g. anthropic/claude-haiku-4-5. Default: the agent file's model, else yours." })),
});

export type SubagentRows = Pick<ToolDefinition<typeof SubagentParams, SubagentDetails>, "renderCall" | "renderResult">;
