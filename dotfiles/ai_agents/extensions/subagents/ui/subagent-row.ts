import { type Component, Text } from "@earendil-works/pi-tui";
import type { SubagentRows } from "../protocol.ts";
import type { Run } from "../run.ts";
import { glimpseLines, statsLine } from "./glimpse.ts";

export function subagentRows(lookup: (id: string) => Run | undefined): SubagentRows {
	return {
		renderCall(args, theme) {
			const mode = args.background ? " (background)" : "";
			const task = (args.task ?? "").split("\n")[0];
			return new Text(
				`${theme.bold("subagent")} ${theme.fg("accent", args.agent ?? "")}${mode} ${theme.fg("dim", task)}`,
				0,
				0,
			);
		},
		renderResult(result, { expanded, isPartial }, theme): Component {
			const id = result.details?.id;
			const run = id === undefined ? undefined : lookup(id);
			if (isPartial) {
				if (!run) return new Text(theme.fg("dim", "starting…"), 0, 0);
				return {
					render: (width) => glimpseLines(run, theme, width),
					invalidate() {},
				};
			}
			const text = result.content.map((c) => (c.type === "text" ? c.text : "")).join("\n");
			const head = run ? theme.fg("dim", `${run.id} · ${statsLine(run)}`) : "";
			const lines = text.split("\n");
			const body =
				expanded || lines.length <= 6
					? text
					: `${lines.slice(0, 6).join("\n")}\n${theme.fg("dim", "… Ctrl+O to expand")}`;
			return new Text([head, body].filter(Boolean).join("\n"), 0, 0);
		},
	};
}
