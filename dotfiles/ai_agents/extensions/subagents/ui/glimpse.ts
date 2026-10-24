import type { Theme } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import type { Activity, Run } from "../run.ts";

const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
export const TICK_MS = 120;
const HOLD_TOOL_MS = 1500;

type Color = Parameters<Theme["fg"]>[0];

const ACTIVITY: Record<Activity, { glyph: string; color: Color; label: string }> = {
	thinking: { glyph: "∴", color: "muted", label: "thinking" },
	writing: { glyph: "✎", color: "text", label: "writing" },
	read: { glyph: "≡", color: "accent", label: "reading" },
	edit: { glyph: "±", color: "warning", label: "editing" },
	bash: { glyph: "❯", color: "success", label: "running" },
	search: { glyph: "⌕", color: "accent", label: "searching" },
	web: { glyph: "◍", color: "accent", label: "browsing" },
	bridge: { glyph: "✉", color: "warning", label: "messaging parent" },
	tool: { glyph: "⚙", color: "muted", label: "using a tool" },
};

function tokens(n: number): string {
	return n >= 1000 ? `${(n / 1000).toFixed(1)}k` : String(n);
}

export function statsLine(run: Run): string {
	const { tokens: total, cost, model } = run.stats();
	return [`${tokens(total)} tok`, cost > 0 ? `$${cost.toFixed(3)}` : undefined, model].filter(Boolean).join(" · ");
}

function shownActivity(run: Run): Activity {
	const held = run.activity === "thinking" && run.lastToolActivity && Date.now() - run.lastToolEndedAt < HOLD_TOOL_MS;
	return held ? run.lastToolActivity! : run.activity;
}

function icon(run: Run, theme: Theme, frame: number): string {
	switch (run.status) {
		case "starting":
			return theme.fg("dim", `${SPINNER[frame % SPINNER.length]} …`);
		case "running": {
			const { glyph, color } = ACTIVITY[shownActivity(run)];
			return `${theme.fg(color, SPINNER[frame % SPINNER.length]!)} ${theme.fg(color, glyph)}`;
		}
		case "waiting":
			return theme.fg("warning", frame % 8 < 4 ? "? ?" : "  ?");
		case "done":
			return theme.fg("success", "✓");
		case "failed":
			return theme.fg("error", "✗");
		case "aborted":
			return theme.fg("dim", "■");
	}
}

function activityText(run: Run): string {
	if (run.status === "waiting") return "waiting for an answer";
	if (run.status !== "running") return run.error ?? run.status;
	const activity = shownActivity(run);
	const { label } = ACTIVITY[activity];
	if (!run.lastTool || activity === "writing") return label;
	return activity === "thinking" ? `${label} · last ${run.lastTool}` : `${label} · ${run.lastTool}`;
}

export function glimpseLines(run: Run, theme: Theme, width: number, frame = 0): string[] {
	const head = `${icon(run, theme, frame)} ${theme.bold(run.id)} ${theme.fg("dim", `· ${activityText(run)} · ${statsLine(run)}`)}`;
	const lines = [truncateToWidth(head, width)];
	if (run.lastText) lines.push(truncateToWidth(theme.fg("dim", `  ⎿ ${run.lastText}`), width));
	return lines;
}
