import { readdirSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseFrontmatter } from "@earendil-works/pi-coding-agent";

export const AGENTS_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), "agents");

const THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];

export interface AgentDef {
	name: string;
	description: string;
	tools: string[];
	model?: string;
	thinking?: string;
	systemPrompt: string;
}

export function loadAgents(): Map<string, AgentDef> {
	const agents = new Map<string, AgentDef>();
	for (const file of readdirSync(AGENTS_DIR).filter((f) => f.endsWith(".md"))) {
		const { frontmatter, body } = parseFrontmatter(readFileSync(path.join(AGENTS_DIR, file), "utf8"));
		const fail = (problem: string): never => {
			throw new Error(`Agent file ${file}: ${problem}`);
		};
		const { description, tools, model, thinking } = frontmatter;
		if (typeof description !== "string" || !description.trim()) fail("'description' must be a non-empty string");
		const toolList = typeof tools === "string" ? tools.split(",") : Array.isArray(tools) ? tools : fail("'tools' must be a list or a comma-separated string");
		if (!toolList.every((t): t is string => typeof t === "string")) fail("every entry in 'tools' must be a string");
		if (model !== undefined && (typeof model !== "string" || !model.includes("/"))) fail("'model' must be 'provider/model-id'");
		if (thinking !== undefined && !THINKING_LEVELS.includes(thinking as string)) fail(`'thinking' must be one of ${THINKING_LEVELS.join(", ")}`);
		if (!body.trim()) fail("the body (system prompt) is empty");
		agents.set(path.basename(file, ".md"), {
			name: path.basename(file, ".md"),
			description: description as string,
			tools: (toolList as string[]).map((t) => t.trim()).filter(Boolean),
			model: model as string | undefined,
			thinking: thinking as string | undefined,
			systemPrompt: body.trim(),
		});
	}
	return agents;
}
