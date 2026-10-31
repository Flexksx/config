import { spawnSync } from "node:child_process";
import { createRequire } from "node:module";
import { dirname, resolve } from "node:path";
import type { Finding } from "../core/finding.ts";

const require = createRequire(import.meta.url);
const biome = resolve(dirname(require.resolve("@biomejs/biome/package.json")), "bin/biome");

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
	const result = spawnSync(
		process.execPath,
		[
			biome,
			"lint",
			`--config-path=${config}`,
			"--reporter=json",
			"--max-diagnostics=none",
			...paths,
		],
		{ encoding: "utf8", maxBuffer: 32 * 1024 * 1024 },
	);
	if (result.error || ![0, 1].includes(result.status ?? -1)) {
		throw new Error(`Biome failed: ${result.error?.message ?? result.stderr}`);
	}
	const output: { diagnostics: Diagnostic[] } = JSON.parse(result.stdout);
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
