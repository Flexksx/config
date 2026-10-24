import type { ExtensionAPI, ExtensionContext, Theme, ThemeColor } from "@earendil-works/pi-coding-agent";
import { sliceByColumn, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const FRAME_INTERVAL_MS = 70;
const SPLASH_DURATION_MS = 700;
const SPLASH_START_COLUMNS = 1;
const GAUGE_CELLS = 10;
const FULL_PERCENT = 100;
const WARNING_PERCENT = 60;
const ERROR_PERCENT = 85;
const TOKENS_PER_KILO = 1000;
const COMPACT_TOKENS_AT = 10;
const COST_DECIMALS = 2;
const BAR_PADDING = 1;
const SEGMENT_GAP = "  ";
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const IDLE_GLYPH = "◆";
const FILLED_CELL = "█";
const EMPTY_CELL = "░";
const PLACEHOLDER = "—";
const NO_MODEL = "no model";
const UNKNOWN_TOKENS = "…";

type Snapshot = {
	model: string;
	provider: string;
	effort: string;
	tokens: number | null;
	window: number;
	percent: number | null;
	cost: number;
};

type Fitted = {
	text: string;
	width: number;
};

type BarInput = {
	theme: Theme;
	snapshot: Snapshot;
	busy: boolean;
	frame: number;
	width: number;
	splashStart: number;
};

const sessionCost = (current: ExtensionContext): number => {
	let cost = 0;
	for (const entry of current.sessionManager.getBranch()) {
		if (entry.type !== "message" || entry.message.role !== "assistant") continue;
		const used = (entry.message as { usage?: { cost?: { total?: number } } }).usage;
		cost += used?.cost?.total ?? 0;
	}
	return cost;
};

const snapshotOf = (current: ExtensionContext): Snapshot => {
	const model = current.model;
	const usage = current.getContextUsage();
	return {
		model: model?.name || model?.id || NO_MODEL,
		provider: model?.provider ?? PLACEHOLDER,
		effort: model?.reasoning ? (current.thinkingLevel ?? "off") : PLACEHOLDER,
		tokens: usage?.tokens ?? null,
		window: usage?.contextWindow ?? model?.contextWindow ?? 0,
		percent: usage?.percent ?? null,
		cost: sessionCost(current),
	};
};

const formatTokenCount = (count: number | null): string => {
	if (count === null) return UNKNOWN_TOKENS;
	if (count < TOKENS_PER_KILO) return `${count}`;
	const kilo = count / TOKENS_PER_KILO;
	if (kilo >= COMPACT_TOKENS_AT) return `${Math.round(kilo)}k`;
	return `${kilo.toFixed(1).replace(/\.0$/, "")}k`;
};

const renderTokens = (snapshot: Snapshot): string => {
	const used = formatTokenCount(snapshot.tokens);
	return snapshot.window > 0 ? `${used}/${formatTokenCount(snapshot.window)}` : used;
};

const gaugeLevel = (percent: number): ThemeColor => {
	if (percent >= ERROR_PERCENT) return "error";
	if (percent >= WARNING_PERCENT) return "warning";
	return "success";
};

const renderGauge = (theme: Theme, percent: number | null): string => {
	if (percent === null) return `${theme.fg("dim", EMPTY_CELL.repeat(GAUGE_CELLS))} ${theme.fg("dim", "--")}`;
	const level = gaugeLevel(percent);
	const filled = Math.min(GAUGE_CELLS, Math.round((percent / FULL_PERCENT) * GAUGE_CELLS));
	const bar = theme.fg(level, FILLED_CELL.repeat(filled)) + theme.fg("dim", EMPTY_CELL.repeat(GAUGE_CELLS - filled));
	return `${bar} ${theme.fg(level, `${Math.round(percent)}%`)}`;
};

const wipe = (line: string, width: number, splashStart: number): string => {
	const elapsed = Date.now() - splashStart;
	if (elapsed >= SPLASH_DURATION_MS) return line;
	const revealed = Math.max(SPLASH_START_COLUMNS, Math.round((elapsed / SPLASH_DURATION_MS) * width));
	return sliceByColumn(line, 0, revealed);
};

const fitHead = (parts: string[], limit: number): Fitted => {
	const kept: string[] = [];
	let width = 0;
	for (const part of parts) {
		const added = kept.length === 0 ? visibleWidth(part) : visibleWidth(SEGMENT_GAP) + visibleWidth(part);
		if (width + added > limit) break;
		kept.push(part);
		width += added;
	}
	if (kept.length === 0) {
		const first = parts[0];
		if (first === undefined) return { text: "", width: 0 };
		const text = truncateToWidth(first, Math.max(0, limit));
		return { text, width: visibleWidth(text) };
	}
	return { text: kept.join(SEGMENT_GAP), width };
};

const fitTail = (core: string, extras: string[], limit: number): Fitted => {
	let text = core;
	for (const extra of extras) {
		const extended = `${text}${SEGMENT_GAP}${extra}`;
		if (visibleWidth(extended) > limit) break;
		text = extended;
	}
	if (visibleWidth(text) <= limit) return { text, width: visibleWidth(text) };
	const truncated = truncateToWidth(text, Math.max(0, limit));
	return { text: truncated, width: visibleWidth(truncated) };
};

const renderBar = ({ theme, snapshot, busy, frame, width, splashStart }: BarInput): string => {
	const spinner = SPINNER_FRAMES[frame % SPINNER_FRAMES.length] ?? IDLE_GLYPH;
	const glyph = theme.fg(busy ? "accent" : "dim", busy ? spinner : IDLE_GLYPH);
	const model = `${glyph} ${theme.style(snapshot.model, { fg: "text", bold: true })}`;
	const effort = theme.fg("muted", `effort:${snapshot.effort}`);
	const provider = theme.fg("muted", snapshot.provider);

	const gauge = renderGauge(theme, snapshot.percent);
	const tokens = theme.fg("dim", renderTokens(snapshot));
	const cost = theme.fg("dim", `$${snapshot.cost.toFixed(COST_DECIMALS)}`);

	const inner = Math.max(1, width - BAR_PADDING * 2);
	const tail = fitTail(gauge, [tokens, cost], Math.floor(inner / 2));
	const head = fitHead([model, effort, provider], Math.max(1, inner - tail.width - visibleWidth(SEGMENT_GAP)));
	const gap = Math.max(1, inner - head.width - tail.width);
	const line = `${" ".repeat(BAR_PADDING)}${head.text}${" ".repeat(gap)}${tail.text}`;

	const wiped = wipe(line, width, splashStart);
	const padded = wiped + " ".repeat(Math.max(0, width - visibleWidth(wiped)));
	return theme.style(truncateToWidth(padded, width), { bg: "selectedBg" });
};

const headerExtension = (pi: ExtensionAPI) => {
	let context: ExtensionContext | undefined;
	let snapshot: Snapshot = {
		model: NO_MODEL,
		provider: PLACEHOLDER,
		effort: PLACEHOLDER,
		tokens: null,
		window: 0,
		percent: null,
		cost: 0,
	};
	let busy = false;
	let frame = 0;
	let splashStart = 0;
	let timer: ReturnType<typeof setInterval> | undefined;
	let requestRedraw: (() => void) | undefined;

	const refresh = (next?: ExtensionContext) => {
		if (next) context = next;
		if (!context) return;
		snapshot = snapshotOf(context);
		requestRedraw?.();
	};

	const stopTimer = () => {
		if (!timer) return;
		clearInterval(timer);
		timer = undefined;
	};

	const animate = () => {
		requestRedraw?.();
		if (timer) return;
		const startedAt = Date.now();
		timer = setInterval(() => {
			frame++;
			requestRedraw?.();
			if (!busy && Date.now() - startedAt > SPLASH_DURATION_MS) stopTimer();
		}, FRAME_INTERVAL_MS);
	};

	pi.on("session_start", async (_event, next) => {
		if (next.mode !== "tui") return;
		context = next;
		splashStart = Date.now();
		frame = 0;
		refresh(next);
		next.ui.setWidget(
			"header",
			(tui, theme) => {
				requestRedraw = () => tui.requestRender();
				return {
					invalidate() {},
					dispose() {
						stopTimer();
						requestRedraw = undefined;
					},
					render: (width: number) => [
						renderBar({
							theme: context?.ui.theme ?? theme,
							snapshot,
							busy,
							frame,
							width,
							splashStart,
						}),
					],
				};
			},
			{ placement: "aboveEditor" },
		);
		animate();
	});

	pi.on("agent_start", async () => {
		busy = true;
		animate();
	});

	pi.on("agent_end", async (_event, next) => {
		busy = false;
		refresh(next);
	});

	pi.on("agent_settled", async (_event, next) => refresh(next));
	pi.on("turn_end", async (_event, next) => refresh(next));
	pi.on("message_end", async (_event, next) => refresh(next));
	pi.on("session_compact", async (_event, next) => refresh(next));
	pi.on("model_select", async (_event, next) => refresh(next));
	pi.on("thinking_level_select", async (_event, next) => refresh(next));

	pi.on("session_shutdown", async () => {
		stopTimer();
		requestRedraw = undefined;
		context = undefined;
	});
};

export default headerExtension;
