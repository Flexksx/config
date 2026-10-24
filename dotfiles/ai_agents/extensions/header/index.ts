import { execFileSync } from "node:child_process";
import { homedir, userInfo } from "node:os";
import type { ExtensionAPI, ExtensionContext, Theme, ThemeColor } from "@earendil-works/pi-coding-agent";
import { VERSION } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const FRAME_INTERVAL_MS = 70;
const GAUGE_CELLS = 10;
const FULL_PERCENT = 100;
const WARNING_PERCENT = 60;
const ERROR_PERCENT = 85;
const TOKENS_PER_KILO = 1000;
const COMPACT_TOKENS_AT = 10;
const COST_DECIMALS = 2;
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const IDLE_GLYPH = "◆";
const FILLED_CELL = "█";
const EMPTY_CELL = "░";
const PLACEHOLDER = "—";
const NO_MODEL = "no model";
const UNKNOWN_TOKENS = "…";
const CELL_PADDING = 1;
const DIVIDER_WIDTH = 1;
const LEFT_SHARE = 0.55;
const LEFT_MIN = 24;
const LEFT_MAX = 60;
const STACK_WIDTH = 80;
const STRIP_ROWS = 4;
const STRIP_MIN_HEIGHT = 14;
const COMMAND_WIDTH = 11;
const ART_WIDTH = 19;
const NOON_HOUR = 12;
const EVENING_HOUR = 18;
const BOX_TOP_LEFT = "╭";
const BOX_TOP_RIGHT = "╮";
const BOX_BOTTOM_LEFT = "╰";
const BOX_BOTTOM_RIGHT = "╯";
const BOX_HORIZONTAL = "─";
const BOX_VERTICAL = "│";
const BOX_TEE_TOP = "┬";
const BOX_TEE_BOTTOM = "┴";
const PI_ART = [
	"██████████████████",
	" ████        ████ ",
	" ████        ████ ",
	" ████        ████ ",
	" ████        ████ ",
	" ████        ████▄",
].map((line) => line.padEnd(ART_WIDTH, " "));
const TIPS = [
	["/model", "switch model mid-session"],
	["/tree", "browse this session's branches"],
	["/compact", "summarize to free context"],
	["/export", "write the session to HTML"],
];

type Snapshot = {
	model: string;
	provider: string;
	effort: string;
	tokens: number | null;
	window: number;
	percent: number | null;
	cost: number;
	directory: string;
};

type StripInput = {
	theme: Theme;
	snapshot: Snapshot;
	busy: boolean;
	frame: number;
	width: number;
};

const gitName = (): string => {
	try {
		return execFileSync("git", ["config", "user.name"], {
			encoding: "utf8",
			stdio: ["ignore", "pipe", "ignore"],
		}).trim();
	} catch {
		return "";
	}
};

const capitalise = (word: string): string => word.charAt(0).toUpperCase() + word.slice(1);

const resolveName = (): string => {
	const configured = process.env.PI_HEADER_NAME?.trim();
	if (configured) return configured;
	const fromGit = gitName().split(/\s+/)[0];
	if (fromGit) return capitalise(fromGit);
	return capitalise(userInfo().username);
};

const NAME = resolveName();

const timeOfDay = (hour: number): string => {
	if (hour < NOON_HOUR) return "morning";
	if (hour < EVENING_HOUR) return "afternoon";
	return "evening";
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

const shortenDirectory = (path: string): string => {
	const home = homedir();
	return path.startsWith(`${home}/`) ? `~/${path.slice(home.length + 1)}` : path;
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
		directory: shortenDirectory(current.cwd),
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

const centreCell = (text: string, width: number): string => {
	const clipped = truncateToWidth(text, Math.max(0, width));
	const slack = Math.max(0, width - visibleWidth(clipped));
	const left = Math.floor(slack / 2);
	return `${" ".repeat(left)}${clipped}${" ".repeat(slack - left)}`;
};

const padCell = (text: string, width: number): string => {
	const clipped = truncateToWidth(text, Math.max(0, width));
	return clipped + " ".repeat(Math.max(0, width - visibleWidth(clipped)));
};

const joinRow = (left: string, right: string, width: number): string => {
	if (visibleWidth(left) + visibleWidth(right) + CELL_PADDING > width) return truncateToWidth(left, width);
	const gap = Math.max(CELL_PADDING, width - visibleWidth(left) - visibleWidth(right));
	return `${left}${" ".repeat(gap)}${right}`;
};

const identityColumn = (theme: Theme, snapshot: Snapshot): string[] => [
	theme.style(`${timeOfDay(new Date().getHours())}, ${NAME}`, { fg: "text", bold: true }),
	"",
	...PI_ART.map((line) => theme.fg("accent", line)),
	"",
	theme.style(snapshot.model, { fg: "text", bold: true }),
	theme.fg("muted", `effort:${snapshot.effort} · ${snapshot.provider}`),
	theme.fg("dim", snapshot.directory),
];

const usageColumn = (theme: Theme, snapshot: Snapshot): string[] => [
	theme.fg("dim", "Context"),
	`${renderGauge(theme, snapshot.percent)} ${theme.fg("dim", renderTokens(snapshot))}`,
	theme.fg("dim", `$${snapshot.cost.toFixed(COST_DECIMALS)}`),
	"",
	theme.fg("dim", "Tips"),
	...TIPS.map(([command, text]) => `${theme.fg("accent", command.padEnd(COMMAND_WIDTH, " "))}${theme.fg("dim", text)}`),
];

const frameRow = (theme: Theme, cells: string[], widths: number[]): string => {
	const body = cells
		.map((cell, index) => ` ${padCell(cell, (widths[index] ?? 0) - CELL_PADDING * 2)} `)
		.join(theme.fg("border", BOX_VERTICAL));
	return `${theme.fg("border", BOX_VERTICAL)}${body}${theme.fg("border", BOX_VERTICAL)}`;
};

const boxTop = (theme: Theme, title: string, leftWidth: number, rightWidth: number | undefined): string => {
	const fill = BOX_HORIZONTAL.repeat(Math.max(0, leftWidth - title.length - DIVIDER_WIDTH));
	if (rightWidth === undefined) {
		return theme.fg("border", `${BOX_TOP_LEFT}${BOX_HORIZONTAL}${title}${fill}${BOX_TOP_RIGHT}`);
	}
	return theme.fg(
		"border",
		`${BOX_TOP_LEFT}${BOX_HORIZONTAL}${title}${fill}${BOX_TEE_TOP}${BOX_HORIZONTAL.repeat(rightWidth)}${BOX_TOP_RIGHT}`,
	);
};

const boxBottom = (theme: Theme, leftWidth: number, rightWidth: number | undefined): string => {
	if (rightWidth === undefined) {
		return theme.fg("border", `${BOX_BOTTOM_LEFT}${BOX_HORIZONTAL.repeat(leftWidth)}${BOX_BOTTOM_RIGHT}`);
	}
	return theme.fg(
		"border",
		`${BOX_BOTTOM_LEFT}${BOX_HORIZONTAL.repeat(leftWidth)}${BOX_TEE_BOTTOM}${BOX_HORIZONTAL.repeat(rightWidth)}${BOX_BOTTOM_RIGHT}`,
	);
};

const renderHeaderBox = (theme: Theme, snapshot: Snapshot, width: number, version: string): string[] => {
	const title = ` π ${version} `;
	const inner = Math.max(1, width - DIVIDER_WIDTH * 2);
	const identity = identityColumn(theme, snapshot);
	const usage = usageColumn(theme, snapshot);
	const spacer = Array.from({ length: STRIP_ROWS }, () => "");
	if (width < STACK_WIDTH) {
		const cells = [...identity, "", ...usage];
		const body = cells.map((cell) => frameRow(theme, [cell], [inner]));
		return [...spacer, boxTop(theme, title, inner, undefined), ...body, boxBottom(theme, inner, undefined)];
	}
	const leftWidth = Math.min(LEFT_MAX, Math.max(LEFT_MIN, Math.floor((inner - DIVIDER_WIDTH) * LEFT_SHARE)));
	const rightWidth = Math.max(1, inner - leftWidth - DIVIDER_WIDTH);
	const rowCount = Math.max(identity.length, usage.length);
	const rows = Array.from({ length: rowCount }, (_, index) => [
		centreCell(identity[index] ?? "", leftWidth - CELL_PADDING * 2),
		padCell(usage[index] ?? "", rightWidth - CELL_PADDING * 2),
	]);
	const body = rows.map((cells) => frameRow(theme, cells, [leftWidth, rightWidth]));
	return [...spacer, boxTop(theme, title, leftWidth, rightWidth), ...body, boxBottom(theme, leftWidth, rightWidth)];
};

const renderStrip = ({ theme, snapshot, busy, frame, width }: StripInput): string[] => {
	const title = ` π ${VERSION} `;
	const inner = Math.max(1, width - DIVIDER_WIDTH * 2);
	const cellWidth = Math.max(1, inner - CELL_PADDING * 2);
	const spinner = SPINNER_FRAMES[frame % SPINNER_FRAMES.length] ?? IDLE_GLYPH;
	const glyph = theme.fg(busy ? "accent" : "dim", busy ? spinner : IDLE_GLYPH);
	const model = `${glyph} ${theme.style(snapshot.model, { fg: "text", bold: true })}${theme.fg(
		"muted",
		` · effort:${snapshot.effort} · ${snapshot.provider}`,
	)}`;
	const usage = `${renderGauge(theme, snapshot.percent)}  ${theme.fg("dim", renderTokens(snapshot))}`;
	const spend = `${theme.fg("dim", `$${snapshot.cost.toFixed(COST_DECIMALS)}`)}  ${theme.fg("dim", snapshot.directory)}`;
	return [
		boxTop(theme, title, inner, undefined),
		frameRow(theme, [model], [inner]),
		frameRow(theme, [joinRow(usage, spend, cellWidth)], [inner]),
		boxBottom(theme, inner, undefined),
	];
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
		directory: PLACEHOLDER,
	};
	let busy = false;
	let frame = 0;
	let timer: ReturnType<typeof setInterval> | undefined;
	let requestRedraw: (() => void) | undefined;
	let closeStrip: (() => void) | undefined;

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
		timer = setInterval(() => {
			frame++;
			requestRedraw?.();
			if (!busy) stopTimer();
		}, FRAME_INTERVAL_MS);
	};

	const showBox = (current: ExtensionContext) => {
		current.ui.setHeader((_tui, theme) => ({
			invalidate() {},
			render: (width: number) => renderHeaderBox(theme, snapshot, width, VERSION),
		}));
	};

	const showStrip = (current: ExtensionContext) => {
		void current.ui
			.custom(
				(tui, theme, _keys, done) => {
					requestRedraw = () => tui.requestRender();
					closeStrip = () => done(undefined);
					return {
						invalidate() {},
						dispose() {
							requestRedraw = undefined;
						},
						render: (width: number) =>
							renderStrip({
								theme: context?.ui.theme ?? theme,
								snapshot,
								busy,
								frame,
								width,
							}),
					};
				},
				{
					overlay: true,
					overlayOptions: () => ({
						anchor: "top-left",
						width: "100%",
						row: 0,
						margin: 0,
						maxHeight: STRIP_ROWS,
						nonCapturing: true,
						visible: (_width: number, height: number) => height >= STRIP_MIN_HEIGHT,
					}),
				},
			)
			.catch(() => {});
	};

	pi.on("session_start", async (_event, next) => {
		if (next.mode !== "tui") return;
		context = next;
		frame = 0;
		refresh(next);
		showBox(next);
		showStrip(next);
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
		closeStrip?.();
		closeStrip = undefined;
		requestRedraw = undefined;
		context = undefined;
	});
};

export default headerExtension;
