import type { Theme } from "@earendil-works/pi-coding-agent";
import type { Component, TUI } from "@earendil-works/pi-tui";
import type { Run } from "../run.ts";
import { glimpseLines, TICK_MS } from "./glimpse.ts";

export const createWidget = (visibleRuns: () => Run[]) => {
	return (tui: TUI, theme: Theme): Component & { dispose(): void } => {
		let frame = 0;
		const timer = setInterval(() => {
			if (!visibleRuns().some((r) => r.active)) return;
			frame++;
			tui.requestRender();
		}, TICK_MS);
		return {
			render: (width) => visibleRuns().flatMap((run) => glimpseLines(run, theme, width, frame)),
			invalidate() {},
			dispose: () => clearInterval(timer),
		};
	};
};
