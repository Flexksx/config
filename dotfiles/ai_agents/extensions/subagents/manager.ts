import type { ExtensionAPI, ExtensionContext, ToolDefinition } from "@earendil-works/pi-coding-agent";
import type { AgentDef } from "./agents.ts";
import { createChildSession } from "./child-session.ts";
import { type BridgeDetails, MESSAGE_TYPES, type MessageType, TOOL_NAMES } from "./protocol.ts";
import { type ForegroundOutcome, type Interaction, type PendingAsk, Run } from "./run.ts";
import { clip, errorText, truncate } from "./text.ts";
import type { ToolProxy } from "./tool-proxy.ts";

const SHOW_ENDED_MS = 30_000;

const DID: Record<Interaction["kind"], string> = {
	reply: "replied to its question",
	answer: "answered its question",
	steer: "steered it",
	"follow-up": "sent a follow-up",
};

type Host = Pick<ExtensionAPI, "sendMessage" | "getThinkingLevel">;
type SendOptions = Parameters<ExtensionAPI["sendMessage"]>[1];

export class SubagentManager {
	replyGate = false;
	private readonly runs = new Map<string, Run>();
	private counter = 0;
	private generation = 0;

	constructor(
		private readonly host: Host,
		private readonly proxy: ToolProxy,
		private readonly bridgeTools: (run: Run) => ToolDefinition[],
	) {}

	get(id: string): Run | undefined {
		return this.runs.get(id);
	}

	list(): Run[] {
		return [...this.runs.values()];
	}

	visible(): Run[] {
		return this.list().filter((r) => r.active || Date.now() - (r.endedAt ?? 0) < SHOW_ENDED_MS);
	}

	async spawn(
		ctx: ExtensionContext,
		agent: AgentDef,
		task: string,
		model: string | undefined,
		signal: AbortSignal | undefined,
	): Promise<Run> {
		const tools = this.proxy.split(agent.tools);
		const run = new Run(`${agent.name}-${++this.counter}`, agent, task, ctx.cwd, this.generation);
		this.runs.set(run.id, run);
		try {
			const session = await createChildSession({
				ctx,
				agent,
				runId: run.id,
				model: model ?? agent.model,
				thinkingLevel: agent.thinking ?? this.host.getThinkingLevel(),
				tools: tools.local,
				customTools: [...this.bridgeTools(run), ...tools.proxied],
			});
			if (signal?.aborted || this.stale(run)) {
				session.dispose();
				throw new Error(
					signal?.aborted
						? "Aborted while the subagent was starting"
						: "The session closed while the subagent was starting",
				);
			}
			run.attach(session);
			return run;
		} catch (error) {
			run.status = signal?.aborted ? "aborted" : "failed";
			run.error = errorText(error);
			run.endedAt = Date.now();
			run.changed();
			throw error;
		}
	}

	start(run: Run, text: string): void {
		void this.drive(run, text, "parent");
	}

	async foreground(run: Run, text: string): Promise<ForegroundOutcome> {
		const outcome = await new Promise<ForegroundOutcome>((resolve) => {
			run.foreground = resolve;
			this.start(run, text);
		});
		run.foreground = undefined;
		return outcome;
	}

	message(run: Run, text: string): void {
		this.send(run, MESSAGE_TYPES.message, `${this.from(run)} says:`, text, {
			deliverAs: "steer",
		});
	}

	async ask(run: Run, question: string, signal: AbortSignal | undefined): Promise<string> {
		if (signal?.aborted) throw new Error("Aborted before asking the parent");
		let resolve!: (answer: string) => void;
		let reject!: (error: Error) => void;
		const answer = new Promise<string>((res, rej) => {
			resolve = res;
			reject = rej;
		});
		const ask: PendingAsk = { question, resolve };
		const onAbort = () => reject(new Error("Aborted while waiting for the parent"));
		signal?.addEventListener("abort", onAbort, { once: true });
		run.pendingAsk = ask;
		run.status = "waiting";
		run.changed();
		if (run.foreground) run.foreground({ kind: "ask", question });
		else
			this.send(
				run,
				MESSAGE_TYPES.ask,
				`${this.from(run)} asks (answer with ${TOOL_NAMES.reply} id="${run.id}"):`,
				question,
				{ triggerTurn: true, deliverAs: "steer" },
			);
		try {
			return await answer;
		} finally {
			signal?.removeEventListener("abort", onAbort);
			if (run.pendingAsk === ask) run.pendingAsk = undefined;
			if (run.status === "waiting") run.status = "running";
			run.changed();
		}
	}

	reply(run: Run, ask: PendingAsk, answer: string, by: Interaction["by"]): void {
		if (run.pendingAsk !== ask)
			throw new Error(`The question from ${run.id} was answered or withdrawn before the reply was sent`);
		run.record({ by, kind: by === "user" ? "answer" : "reply", text: answer });
		ask.resolve(`${by === "user" ? "The user" : "Your parent agent"} answered: ${answer}`);
	}

	async input(run: Run, text: string): Promise<void> {
		if (run.pendingAsk) return this.reply(run, run.pendingAsk, text, "user");
		if (!run.session) throw new Error(`${run.id} has no session (${run.status}); nothing was sent`);
		const fromUser = `Message from the user. Your parent sees your reply only if you send it with message_parent.\n\n${text}`;
		if (run.active) {
			await run.session.steer(fromUser);
			run.record({ by: "user", kind: "steer", text });
		} else {
			run.record({ by: "user", kind: "follow-up", text });
			void this.drive(run, fromUser, "user");
		}
	}

	reportInteractions(run: Run): void {
		if (!run.unreported().some((i) => i.by === "user")) return;
		const brief = this.brief(run);
		this.send(
			run,
			MESSAGE_TYPES.interaction,
			`The user worked with ${this.from(run)} directly. For your information; no reply needed:`,
			brief,
			{
				triggerTurn: false,
			},
		);
	}

	async abort(run: Run): Promise<void> {
		await run.session?.abort();
	}

	async shutdown(): Promise<void> {
		this.generation++;
		const ending = this.list();
		this.runs.clear();
		this.proxy.reset();
		for (const run of ending) {
			if (run.active) await run.session?.abort().catch(() => {});
			run.session?.dispose();
		}
	}

	private async drive(run: Run, text: string, origin: Interaction["by"]): Promise<void> {
		const session = run.session!;
		run.status = "running";
		run.error = undefined;
		run.endedAt = undefined;
		run.changed();
		try {
			await session.prompt(text);
			const last = session.messages.findLast((m) => m.role === "assistant");
			if (last?.stopReason === "aborted") run.status = "aborted";
			else if (last?.stopReason === "error") {
				run.status = "failed";
				run.error = last.errorMessage ?? "unknown error";
			} else run.status = "done";
		} catch (error) {
			run.status = "failed";
			run.error = errorText(error);
		}
		run.endedAt = Date.now();
		run.changed();
		if (run.foreground) run.foreground({ kind: "settled" });
		else if (origin === "parent") {
			const interactions = run.unreported().length > 0 ? `\n\n${this.brief(run)}` : "";
			this.send(
				run,
				MESSAGE_TYPES.result,
				`${this.from(run)} ${run.status}:`,
				truncate(run.error ?? run.result()) + interactions,
				{
					triggerTurn: true,
					deliverAs: "followUp",
				},
			);
		}
	}

	private brief(run: Run): string {
		const lines = run
			.unreported()
			.map((i) => `- ${i.by === "user" ? "The user" : "The main agent"} ${DID[i.kind]}: "${clip(i.text)}"`);
		run.markReported();
		return [
			`Interactions with ${run.id}:`,
			...lines,
			`Status: ${run.status}. Latest answer: "${clip(run.result())}"`,
		].join("\n");
	}

	private stale(run: Run): boolean {
		return run.generation !== this.generation;
	}

	private from(run: Run): string {
		return `Subagent ${run.id} (${run.agent.name})`;
	}

	private send(run: Run, type: MessageType, header: string, text: string, options: SendOptions): void {
		if (this.stale(run)) return;
		this.host.sendMessage<BridgeDetails>(
			{
				customType: type,
				content: `${header}\n\n${text}`,
				display: true,
				details: { id: run.id, agent: run.agent.name, text },
			},
			options,
		);
	}
}
