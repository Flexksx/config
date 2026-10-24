import { defineTool, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { type AgentDef, loadAgents } from "../agents.ts";
import type { SubagentManager } from "../manager.ts";
import { type SubagentDetails, SubagentParams, type SubagentRows, TOOL_NAMES } from "../protocol.ts";
import { errorText, truncate } from "../text.ts";
import type { ToolProxy } from "../tool-proxy.ts";

export interface SubagentToolDeps {
	manager: SubagentManager;
	proxy: ToolProxy;
	rows: SubagentRows;
	onSpawn(ctx: ExtensionContext): void;
}

export const subagentTool = ({ manager, proxy, rows, onSpawn }: SubagentToolDeps) => {
	let agents = new Map<string, AgentDef>();
	let agentsError: string | undefined;
	try {
		agents = loadAgents();
	} catch (error) {
		agentsError = errorText(error);
	}

	return defineTool({
		name: TOOL_NAMES.spawn,
		label: "Subagent",
		description: describeAgents(agents, agentsError),
		promptSnippet: "Delegate a focused task to a subagent with its own context",
		promptGuidelines: [
			"Use subagent for focused work whose details should stay out of your context: exact implementation from a spec, an adversarial review, or codebase recon.",
			"Give the subagent a complete, self-contained task. It does not see this conversation.",
			`A foreground subagent returns early if it asks you something; answer with ${TOOL_NAMES.reply}, and its result arrives later as a message.`,
		],
		parameters: SubagentParams,
		...rows,
		prepareLoadout: proxy.captureLoadout,
		async execute(_id, params, signal, onUpdate, ctx) {
			proxy.captureContext(ctx);
			if (agentsError) throw new Error(`${agentsError}. Fix the file, then /reload.`);
			const agent = agents.get(params.agent);
			if (!agent) throw new Error(`Unknown agent '${params.agent}'. Available: ${[...agents.keys()].join(", ")}`);

			onSpawn(ctx);
			const run = await manager.spawn(ctx, agent, params.task, params.model, signal);
			const details: SubagentDetails = { id: run.id };
			if (params.background) {
				manager.start(run, params.task);
				return {
					content: [
						{
							type: "text",
							text: `Started ${run.id} in the background. Its result arrives as a message.`,
						},
					],
					details,
				};
			}

			const stopUpdates = run.onChange(() =>
				onUpdate?.({
					content: [{ type: "text", text: run.lastTool ?? "" }],
					details,
				}),
			);
			const abort = () =>
				void manager
					.abort(run)
					.catch((error) => ctx.ui.notify(`Could not abort ${run.id}: ${errorText(error)}`, "error"));
			signal?.addEventListener("abort", abort, { once: true });
			const outcome = await manager.foreground(run, params.task);
			stopUpdates();
			signal?.removeEventListener("abort", abort);

			if (outcome.kind === "ask") {
				const text = `${run.id} is waiting for an answer:\n\n${outcome.question}\n\nAnswer with ${TOOL_NAMES.reply}. It then continues in the background and its result arrives as a message.`;
				return { content: [{ type: "text", text }], details };
			}
			if (run.status !== "done") throw new Error(truncate(`${run.id} ${run.status}: ${run.error ?? run.result()}`));
			return {
				content: [{ type: "text", text: truncate(run.result()) }],
				details,
			};
		},
	});
};

function describeAgents(agents: Map<string, AgentDef>, error: string | undefined): string {
	const intro = "Run a task in a subagent with its own context and system prompt. Only its final report comes back.";
	if (error) return `${intro}\n\nUnavailable: ${error}`;
	const list = [...agents.values()]
		.map((a) => `- ${a.name}: ${a.description} (tools: ${a.tools.join(", ")})`)
		.join("\n");
	return `${intro}\n\nAgents:\n${list}`;
}
