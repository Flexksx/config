import { readFileSync } from "node:fs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

const CUSTOM_TYPE = "user-invoked-skills";
const SKILL_GLYPH = "\uF02D";
const SKILL_PREFIX = "skill:";
const TOKEN_PATTERN = /\/([a-z0-9][a-z0-9-]*)/gi;
const MIN_TOKEN_LENGTH = 2;

function readSkill(path: string): string | undefined {
	try {
		return readFileSync(path, "utf8").trim();
	} catch {
		return undefined;
	}
}

export default (pi: ExtensionAPI) => {
	pi.registerMessageRenderer<{ skills: string[] }>(CUSTOM_TYPE, (message, { expanded }, theme) => {
		const names = message.details?.skills.join(", ") ?? "";
		const header = `${theme.fg("accent", SKILL_GLYPH)} ${theme.fg("dim", names)}`;
		if (!expanded) {
			return new Text(header, 0, 0);
		}
		const body = typeof message.content === "string" ? message.content : "";
		return new Text(`${header}\n${theme.fg("dim", body)}`, 0, 0);
	});

	pi.on("before_agent_start", async (event, ctx) => {
		if (event.messageType !== "user" || !event.prompt.includes("/")) {
			return;
		}

		const skills = pi
			.getCommands()
			.filter((command) => command.source === "skill")
			.map((command) => ({
				name: command.name.slice(SKILL_PREFIX.length),
				path: command.sourceInfo.path,
			}));

		const loaded = new Map<string, string>();
		const ambiguous: string[] = [];

		for (const match of event.prompt.matchAll(TOKEN_PATTERN)) {
			const token = match[1];
			if (token.length < MIN_TOKEN_LENGTH) {
				continue;
			}
			const lower = token.toLowerCase();
			const prefixed = skills.filter((skill) => skill.name.startsWith(lower));
			const skill =
				skills.find((candidate) => candidate.name === lower) ?? (prefixed.length === 1 ? prefixed[0] : undefined);
			if (!skill) {
				if (prefixed.length > 1) {
					const names = prefixed.map((candidate) => candidate.name).join(", ");
					ambiguous.push(`/${token} matches ${names}`);
				}
				continue;
			}
			loaded.set(skill.name, skill.path);
		}

		if (ambiguous.length > 0) {
			ctx.ui.notify(ambiguous.join("\n"), "warning");
		}
		if (loaded.size === 0) {
			return;
		}

		const blocks: string[] = [];
		for (const [name, path] of loaded) {
			const body = readSkill(path);
			if (body === undefined) {
				ctx.ui.notify(`Cannot read ${path}`, "error");
				continue;
			}
			blocks.push(`<skill name="${name}" location="${path}">\n${body}\n</skill>`);
		}

		return {
			message: {
				customType: CUSTOM_TYPE,
				content: `<user_invoked_skills>\n${blocks.join("\n\n")}\n</user_invoked_skills>`,
				display: true,
				details: { skills: [...loaded.keys()] },
			},
		};
	});
};
