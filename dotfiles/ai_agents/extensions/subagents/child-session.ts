import path from "node:path";
import {
	type AgentSession,
	createAgentSession,
	DefaultResourceLoader,
	type ExtensionContext,
	getAgentDir,
	ModelRuntime,
	SessionManager,
	SettingsManager,
	type ToolDefinition,
} from "@earendil-works/pi-coding-agent";
import type { AgentDef } from "./agents.ts";

let runtimePromise: Promise<ModelRuntime> | undefined;

async function modelRuntime(ctx: ExtensionContext): Promise<ModelRuntime> {
	const agentDir = getAgentDir();
	runtimePromise ??= ModelRuntime.create({
		authPath: path.join(agentDir, "auth.json"),
		modelsPath: path.join(agentDir, "models.json"),
		modelsStorePath: path.join(agentDir, "models-store.json"),
	}).catch((error: unknown) => {
		runtimePromise = undefined;
		throw error;
	});
	const runtime = await runtimePromise;
	for (const id of ctx.modelRegistry.getRegisteredProviderIds()) {
		const native = ctx.modelRegistry.getRegisteredNativeProvider(id);
		const config = ctx.modelRegistry.getRegisteredProviderConfig(id);
		if (native) runtime.registerNativeProvider(native);
		if (config) runtime.registerProvider(id, config);
	}
	return runtime;
}

function splitModelRef(ref: string): [string, string] {
	const slash = ref.indexOf("/");
	if (slash <= 0) throw new Error(`Model '${ref}' must be 'provider/model-id'`);
	return [ref.slice(0, slash), ref.slice(slash + 1)];
}

type CreateOptions = NonNullable<Parameters<typeof createAgentSession>[0]>;

export interface ChildOptions {
	ctx: ExtensionContext;
	agent: AgentDef;
	runId: string;
	model: string | undefined;
	thinkingLevel: string;
	tools: string[];
	customTools: ToolDefinition[];
}

export async function createChildSession(opts: ChildOptions): Promise<AgentSession> {
	const { ctx, agent } = opts;
	const ref = opts.model ?? (ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined);
	if (!ref) throw new Error("No model: none was given and the main session has none");
	const [provider, id] = splitModelRef(ref);

	const runtime = await modelRuntime(ctx);
	if (ctx.modelRegistry.getProviderAuthStatus(provider).source === "runtime") {
		const key = await ctx.modelRegistry.getApiKeyForProvider(provider);
		if (key !== undefined) await runtime.setRuntimeApiKey(provider, key);
	}
	const model = runtime.getModel(provider, id);
	if (!model) throw new Error(`Model ${ref} is not available`);
	if (model.api === "pi-virtual") throw new Error(`Model ${ref} is virtual. Pass a physical 'provider/model-id' for ${agent.name}.`);

	const cwd = ctx.cwd;
	const agentDir = getAgentDir();
	const settingsManager = SettingsManager.inMemory({}, { projectTrusted: ctx.isProjectTrusted() });
	const loader = new DefaultResourceLoader({
		cwd,
		agentDir,
		settingsManager,
		noExtensions: true,
		noSkills: true,
		noPromptTemplates: true,
		noContextFiles: true,
		noThemes: true,
		systemPrompt: [
			agent.systemPrompt,
			`You are subagent '${opts.runId}', started by a parent agent. Your final message is handed back to it, so make it a short, complete report.`,
			"Use message_parent for progress the parent must know now. Use ask_parent only when you cannot continue without an answer.",
			"The user can also message you directly. Your replies to the user stay with the user: the parent sees only your final report on its own task and what you send with message_parent. When the user asks you to tell, report, or send something to the parent, send the complete content with message_parent.",
		].join("\n\n"),
		appendSystemPromptOverride: () => [],
	});
	await loader.reload();

	const { session } = await createAgentSession({
		cwd,
		agentDir,
		modelRuntime: runtime,
		model,
		thinkingLevel: opts.thinkingLevel as CreateOptions["thinkingLevel"],
		settingsManager,
		resourceLoader: loader,
		sessionManager: SessionManager.inMemory(cwd),
		tools: [...opts.tools, ...opts.customTools.map((t) => t.name)],
		customTools: opts.customTools,
	});
	await session.bindExtensions({ mode: "print" });
	return session;
}
