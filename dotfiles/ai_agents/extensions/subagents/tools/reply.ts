import { defineTool } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import type { SubagentManager } from "../manager.ts";
import { TOOL_NAMES } from "../protocol.ts";

export function replyTool(manager: SubagentManager) {
	return defineTool({
		name: TOOL_NAMES.reply,
		label: "Reply to subagent",
		description: `Answer a question a subagent asked with ${TOOL_NAMES.ask}. The user may review, edit, or reject the reply first.`,
		parameters: Type.Object({
			id: Type.String({ description: "Subagent id, e.g. worker-1" }),
			message: Type.String(),
		}),
		async execute(_id, { id, message }, _signal, _onUpdate, ctx) {
			const run = manager.get(id);
			const ask = run?.pendingAsk;
			if (!run || !ask) throw new Error(`Subagent ${id} has no open question`);
			let answer = message;
			if (manager.replyGate) {
				if (!ctx.hasUI) throw new Error("The reply gate is on, but there is no UI to review the reply. Turn it off with /subagents gate.");
				const choice = await ctx.ui.select(`Reply to ${id}?\n\nQuestion: ${ask.question}\n\nDraft: ${message}`, [
					"Send",
					"Edit, then send",
					"Reject with a note",
				]);
				if (choice === "Edit, then send") answer = (await ctx.ui.editor(`Reply to ${id}`, message))?.trim() ?? "";
				if (choice === undefined || choice === "Reject with a note" || !answer) {
					const note = await ctx.ui.input("Note for the main agent (optional)");
					throw new Error(`The user rejected this reply.${note ? ` Note: ${note}` : ""}`);
				}
			}
			manager.reply(run, ask, answer, "parent");
			const text = answer === message ? `Sent to ${id}.` : `The user edited your reply. Sent to ${id}: ${answer}`;
			return { content: [{ type: "text", text }], details: undefined };
		},
	});
}
