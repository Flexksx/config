import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { Box, Text } from "@earendil-works/pi-tui";
import { type BridgeDetails, MESSAGE_TYPES } from "../protocol.ts";

type Color = Parameters<Theme["fg"]>[0];

export function registerMessageRenderers(pi: ExtensionAPI): void {
	const labels: Record<string, [string, Color]> = {
		[MESSAGE_TYPES.message]: ["says", "accent"],
		[MESSAGE_TYPES.ask]: ["asks", "warning"],
		[MESSAGE_TYPES.result]: ["finished", "success"],
		[MESSAGE_TYPES.interaction]: ["was used directly", "muted"],
	};
	for (const [type, [verb, color]] of Object.entries(labels)) {
		pi.registerMessageRenderer<BridgeDetails>(type, (message, { expanded, outputPad }, theme) => {
			if (!message.details) return undefined;
			const { id, agent, text: content } = message.details;
			const lines = content.split("\n");
			const shown =
				expanded || lines.length <= 8
					? content
					: `${lines.slice(0, 8).join("\n")}\n${theme.fg("dim", "… Ctrl+O to expand")}`;
			const who = `${id} (${agent})`;
			const box = new Box(outputPad, 1, (t) => theme.bg("customMessageBg", t));
			box.addChild(new Text(`${theme.fg(color, theme.bold(`◆ ${who} ${verb}`))}\n${shown}`, 0, 0));
			return box;
		});
	}
}
