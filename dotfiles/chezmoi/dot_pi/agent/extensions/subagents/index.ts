import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { registerSubagentsCommand } from "./command.ts";
import { SubagentManager } from "./manager.ts";
import { TOOL_NAMES } from "./protocol.ts";
import { createToolProxy } from "./tool-proxy.ts";
import { bridgeTools } from "./tools/bridge.ts";
import { replyTool } from "./tools/reply.ts";
import { subagentTool } from "./tools/subagent.ts";
import { registerMessageRenderers } from "./ui/messages.ts";
import { installRendererCapture } from "./ui/renderer-capture.ts";
import { subagentRows } from "./ui/subagent-row.ts";
import { createWidget } from "./ui/widget.ts";

export default function (pi: ExtensionAPI) {
	const proxy = createToolProxy(new Set([TOOL_NAMES.spawn, TOOL_NAMES.reply]));
	const manager: SubagentManager = new SubagentManager(pi, proxy, (run) => bridgeTools(run, manager));
	let widgetShown = false;

	const showWidget = (ctx: ExtensionContext) => {
		if (widgetShown || ctx.mode !== "tui") return;
		widgetShown = true;
		ctx.ui.setWidget(
			"subagents",
			createWidget(() => manager.visible()),
		);
	};

	registerMessageRenderers(pi);
	pi.registerTool(
		subagentTool({
			manager,
			proxy,
			rows: subagentRows((id) => manager.get(id)),
			onSpawn: showWidget,
		}),
	);
	pi.registerTool(replyTool(manager));
	registerSubagentsCommand(pi, manager);

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode === "tui") installRendererCapture();
	});

	pi.on("session_shutdown", async () => {
		widgetShown = false;
		await manager.shutdown();
	});
}
