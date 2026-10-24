import { defineTool, type ExtensionToolContext, type ToolDefinition, type ToolLoadout } from "@earendil-works/pi-coding-agent";

const BUILTINS = new Set(["read", "bash", "edit", "write", "grep", "find", "ls"]);
const NEVER_PROXY = new Set(["codemode", "tool_search"]);

export interface ChildTools {
	local: string[];
	proxied: ToolDefinition[];
}

export type ToolProxy = ReturnType<typeof createToolProxy>;

export function createToolProxy(ownTools: ReadonlySet<string>) {
	let loadout: ToolLoadout | undefined;
	let bridge: ExtensionToolContext | undefined;

	function proxy(tool: ToolLoadout["registered"][number]): ToolDefinition {
		return defineTool({
			name: tool.name,
			label: tool.label,
			description: tool.description,
			parameters: tool.parameters,
			async execute(_id, args, signal, onUpdate) {
				if (!bridge) throw new Error(`${tool.name} is unavailable: the main session changed since this subagent started`);
				const outcome = await bridge.executeTool(tool.name, args, { signal, onUpdate });
				return { ...outcome.result, isError: outcome.isError };
			},
		});
	}

	return {
		captureLoadout(next: ToolLoadout) {
			loadout = next;
			return undefined;
		},
		captureContext(next: ExtensionToolContext) {
			bridge = next;
		},
		reset() {
			bridge = undefined;
		},
		split(allow: readonly string[]): ChildTools {
			const callable = new Set(loadout?.callable.map((t) => t.name));
			const result: ChildTools = { local: [], proxied: [] };
			const unknown: string[] = [];
			for (const name of allow) {
				if (BUILTINS.has(name)) {
					result.local.push(name);
					continue;
				}
				const tool = loadout?.registered.find((t) => t.name === name);
				if (!tool || !callable.has(name) || ownTools.has(name) || NEVER_PROXY.has(name)) unknown.push(name);
				else result.proxied.push(proxy(tool));
			}
			if (unknown.length > 0) throw new Error(`Tools not available to subagents: ${unknown.join(", ")}`);
			return result;
		},
	};
}
