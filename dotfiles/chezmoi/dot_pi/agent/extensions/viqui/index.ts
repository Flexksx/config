import { createHash } from "node:crypto";
import { existsSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { extname, join, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const cli =
	process.env.VIQUI_BIN ?? join(homedir(), ".local/share/viqui/current/viqui");
const supported = new Set([
	".py",
	".js",
	".jsx",
	".mjs",
	".cjs",
	".ts",
	".tsx",
]);
const gitTimeout = 15000;
const scanTimeout = 60000;
const nullByte = "\0";

export const supportedPath = (path: string): boolean =>
	supported.has(extname(path));

const candidate = (path: string): string | undefined => {
	const absolute = resolve(path);
	if (!supportedPath(absolute) || !existsSync(absolute)) {
		return undefined;
	}
	return statSync(absolute).isFile() ? absolute : undefined;
};

export const formatFindings = (
	findings: { file: string; line: number; message: string }[],
): string =>
	`Review harness findings:\n${findings
		.map((finding) => `${finding.file}:${finding.line}: ${finding.message}`)
		.join("\n")}`;

const viquiExtension = (pi: ExtensionAPI) => {
	const seen = new Map<string, string>();

	const digest = (path: string): string | undefined => {
		try {
			return createHash("sha256").update(readFileSync(path)).digest("hex");
		} catch {
			return undefined;
		}
	};

	const changedFiles = async (
		cwd: string,
		signal: AbortSignal | undefined,
	): Promise<string[]> => {
		const options = { cwd, signal, timeout: gitTimeout };
		const root = await pi.exec("git", ["rev-parse", "--show-toplevel"], options);
		if (root.code !== 0) {
			return [];
		}
		const repository = root.stdout.trim();
		const outputs = await Promise.all([
			pi.exec("git", ["diff", "--name-only", "-z", "--diff-filter=ACMR"], options),
			pi.exec(
				"git",
				["diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR"],
				options,
			),
			pi.exec(
				"git",
				["ls-files", "--others", "--exclude-standard", "--full-name", "-z"],
				options,
			),
		]);
		return outputs
			.flatMap((output) => output.stdout.split(nullByte).filter(Boolean))
			.map((path) => resolve(repository, path));
	};

	const targets = async (
		toolName: string,
		input: Record<string, unknown>,
		cwd: string,
		signal: AbortSignal | undefined,
	): Promise<string[]> => {
		if (toolName === "edit" || toolName === "write") {
			return typeof input.path === "string" ? [input.path] : [];
		}
		return toolName === "bash" ? changedFiles(cwd, signal) : [];
	};

	pi.on("tool_result", async (event, ctx) => {
		if (event.parentToolCallId || !existsSync(cli)) {
			return;
		}
		let paths: string[];
		try {
			paths = (await targets(event.toolName, event.input, ctx.cwd, ctx.signal))
				.map((path) => candidate(resolve(ctx.cwd, path)))
				.filter((path): path is string => Boolean(path));
		} catch {
			return;
		}
		const pending: { path: string; digest: string }[] = [];
		for (const path of paths) {
			const current = digest(path);
			if (current && seen.get(path) !== current) {
				pending.push({ path, digest: current });
			}
		}
		if (!pending.length) {
			return;
		}
		let stdout: string;
		try {
			const result = await pi.exec(
				cli,
				["scan", ...pending.map(({ path }) => path)],
				{ cwd: ctx.cwd, signal: ctx.signal, timeout: scanTimeout },
			);
			if (result.code !== 0) {
				return;
			}
			stdout = result.stdout;
		} catch {
			return;
		}
		let findings: { file: string; line: number; message: string }[];
		try {
			findings = JSON.parse(stdout);
		} catch {
			return;
		}
		for (const { path, digest: current } of pending) {
			seen.set(path, current);
		}
		if (!findings.length) {
			return;
		}
		return {
			content: [
				...event.content,
				{ type: "text" as const, text: formatFindings(findings) },
			],
			structuredContent: event.structuredContent,
		};
	});
};

export default viquiExtension;
