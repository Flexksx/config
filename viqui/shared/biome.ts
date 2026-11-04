import { dirname, resolve } from "node:path";
import type { Finding } from "../core/finding.ts";

const biome = resolve(
	dirname(Bun.resolveSync("@biomejs/biome/package.json", import.meta.dir)),
	"bin/biome",
);

const runBiome = (config: string, paths: string[]) => {
	let result: { exitCode: number; stdout: Buffer; stderr: Buffer };
	try {
		result = Bun.spawnSync({
			cmd: [
				process.execPath,
				biome,
				"lint",
				`--config-path=${config}`,
				"--reporter=json",
				"--max-diagnostics=none",
				...paths,
			],
			stdout: "pipe",
			stderr: "pipe",
		});
	} catch (error) {
		throw new Error(`Biome failed: ${error instanceof Error ? error.message : String(error)}`);
	}
	if (![0, 1].includes(result.exitCode)) {
		throw new Error(`Biome failed: ${result.stderr.toString()}`);
	}
	return result;
};

type Diagnostic = {
	category: string;
	location: { path: string; start: { line: number; column: number } };
};

export const scanBiome = (
	config: string,
	categories: string[],
	rule: string,
	message: string,
	paths: string[],
): Finding[] => {
	const result = runBiome(config, paths);
	const output: { diagnostics: Diagnostic[] } = JSON.parse(result.stdout.toString());
	if (output.diagnostics.some((item) => !categories.includes(item.category))) {
		throw new Error(`Biome returned unexpected diagnostics: ${JSON.stringify(output.diagnostics)}`);
	}
	return output.diagnostics.map((item) => ({
		rule,
		file: resolve(item.location.path),
		line: item.location.start.line,
		column: item.location.start.column,
		message,
	}));
};
