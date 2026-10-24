import type { Theme } from "@earendil-works/pi-coding-agent";
import {
	type Component,
	type Focusable,
	Input,
	matchesKey,
	type TUI,
	truncateToWidth,
	visibleWidth,
} from "@earendil-works/pi-tui";
import type { Run } from "../run.ts";
import { glimpseLines, TICK_MS } from "./glimpse.ts";
import { Transcript } from "./transcript.ts";

export interface TeleportActions {
	submit(text: string): void;
	abort(): void;
}

export class TeleportView implements Component, Focusable {
	private readonly input = new Input();
	private readonly transcript?: Transcript;
	private readonly unsubscribe: Array<() => void> = [];
	private readonly timer: ReturnType<typeof setInterval>;
	private frame = 0;
	private scroll = 0;
	private _focused = false;

	constructor(
		private readonly tui: TUI,
		private readonly theme: Theme,
		private readonly run: Run,
		private readonly actions: TeleportActions,
		private readonly done: () => void,
	) {
		this.input.onSubmit = (value) => {
			if (value.trim()) actions.submit(value.trim());
			this.input.setValue("");
			this.scroll = 0;
		};
		this.input.onEscape = done;
		if (run.session) {
			const transcript = new Transcript(tui, run.session, run.cwd);
			this.transcript = transcript;
			this.unsubscribe.push(run.session.subscribe((event) => transcript.handle(event)));
		}
		this.unsubscribe.push(run.onChange(() => tui.requestRender()));
		this.timer = setInterval(() => {
			if (!run.active) return;
			this.frame++;
			tui.requestRender();
		}, TICK_MS);
	}

	get focused(): boolean {
		return this._focused;
	}

	set focused(value: boolean) {
		this._focused = value;
		this.input.focused = value;
	}

	handleInput(data: string): void {
		const page = this.bodyHeight();
		if (matchesKey(data, "escape")) this.done();
		else if (matchesKey(data, "ctrl+x")) this.actions.abort();
		else if (matchesKey(data, "ctrl+o")) this.transcript?.toggleExpanded();
		else if (matchesKey(data, "up")) this.scroll += 1;
		else if (matchesKey(data, "down")) this.scroll = Math.max(0, this.scroll - 1);
		else if (matchesKey(data, "pageUp")) this.scroll += page;
		else if (matchesKey(data, "pageDown")) this.scroll = Math.max(0, this.scroll - page);
		else this.input.handleInput(data);
		this.tui.requestRender();
	}

	private bodyHeight(): number {
		return Math.max(5, Math.floor(this.tui.terminal.rows * 0.85) - 8);
	}

	render(width: number): string[] {
		const th = this.theme;
		const inner = width - 4;
		const row = (content: string) => {
			const text = truncateToWidth(content, inner);
			return `${th.fg("border", "│")} ${text}${" ".repeat(Math.max(0, inner - visibleWidth(text)))} ${th.fg("border", "│")}`;
		};

		const transcript = this.transcript?.container.render(inner) ?? [th.fg("dim", "starting…")];
		const height = this.bodyHeight();
		this.scroll = Math.min(this.scroll, Math.max(0, transcript.length - height));
		const end = transcript.length - this.scroll;
		const body = transcript.slice(Math.max(0, end - height), end);
		while (body.length < height) body.unshift("");

		const title = ` ${this.run.id} · ${this.run.agent.name} `;
		const lines = [th.fg("border", `╭─${title}${"─".repeat(Math.max(0, width - 3 - visibleWidth(title)))}╮`)];
		lines.push(
			row(
				glimpseLines(this.run, th, inner, this.frame)[0]! +
					th.fg("dim", this.scroll > 0 ? ` · scrolled ${this.scroll}` : ""),
			),
		);
		lines.push(...body.map(row));
		const ask = this.run.pendingAsk;
		lines.push(row(ask ? th.fg("warning", `? ${ask.question.replace(/\s+/g, " ")}`) : ""));
		const verb = ask ? "answer" : this.run.active ? "steer" : "continue";
		lines.push(row(`${th.fg("accent", verb)} ${this.input.render(inner - verb.length - 1)[0] ?? ""}`));
		lines.push(row(th.fg("dim", "Enter send · ↑↓ PgUp PgDn scroll · Ctrl+O expand · Ctrl+X abort · Esc back")));
		lines.push(th.fg("border", `╰${"─".repeat(width - 2)}╯`));
		return lines;
	}

	invalidate(): void {
		this.input.invalidate();
		this.transcript?.container.invalidate();
	}

	dispose(): void {
		clearInterval(this.timer);
		for (const off of this.unsubscribe) off();
	}
}
