import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { SubagentManager } from "./manager.ts";
import type { Run } from "./run.ts";
import { errorText } from "./text.ts";
import { TeleportView } from "./ui/teleport.ts";

export function registerSubagentsCommand(pi: ExtensionAPI, manager: SubagentManager): void {
	pi.registerCommand("subagents", {
		description: "Teleport into a subagent. '/subagents gate' toggles review of replies to subagents.",
		handler: async (args, ctx) => {
			const arg = args.trim();
			if (arg === "gate") {
				manager.replyGate = !manager.replyGate;
				ctx.ui.setStatus("subagents-gate", manager.replyGate ? "reply gate on" : undefined);
				ctx.ui.notify(`Reply gate ${manager.replyGate ? "on" : "off"}`, "info");
				return;
			}
			if (arg) return ctx.ui.notify(`Unknown argument '${arg}'. Use '/subagents' or '/subagents gate'.`, "error");
			const list = manager.list().reverse();
			if (list.length === 0) return ctx.ui.notify("No subagents in this session", "info");
			const labels = list.map((r) => `${r.id} · ${r.status} · ${r.task.replace(/\s+/g, " ").slice(0, 60)}`);
			const pick = await ctx.ui.select("Teleport into", labels);
			const run = pick === undefined ? undefined : list[labels.indexOf(pick)];
			if (run) await teleport(manager, run, ctx);
		},
	});
}

async function teleport(manager: SubagentManager, run: Run, ctx: ExtensionContext): Promise<void> {
	const report = (action: string) => (error: unknown) => ctx.ui.notify(`Could not ${action} ${run.id}: ${errorText(error)}`, "error");
	await ctx.ui.custom<void>(
		(tui, theme, _keybindings, done) =>
			new TeleportView(
				tui,
				theme,
				run,
				{
					submit: (text) => void manager.input(run, text).catch(report("send to")),
					abort: () => void manager.abort(run).catch(report("abort")),
				},
				() => done(),
			),
		{ overlay: true, overlayOptions: { width: "90%", maxHeight: "90%" } },
	);
	manager.reportInteractions(run);
}
