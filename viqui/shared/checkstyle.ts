import { join, resolve } from "node:path";
import type { Finding } from "../core/finding.ts";

export const CHECKSTYLE_VERSION = "10.26.1";
export const CHECKSTYLE_SHA256 = "e41c24433723ba310a30e41da4f449c105ad47cab2ae9e6be5e06606a647dbca";
const CHECKSTYLE_FILE = `checkstyle-${CHECKSTYLE_VERSION}-all.jar`;
const CHECKSTYLE_URL = `https://github.com/checkstyle/checkstyle/releases/download/checkstyle-${CHECKSTYLE_VERSION}/${CHECKSTYLE_FILE}`;

const digest = (bytes: ArrayBuffer): string => {
	const hasher = new Bun.CryptoHasher("sha256");
	hasher.update(bytes);
	return hasher.digest("hex");
};

export const ensureCheckstyleJar = async (target: string): Promise<string> => {
	if (await Bun.file(target).exists()) {
		if (digest(await Bun.file(target).arrayBuffer()) === CHECKSTYLE_SHA256) {
			return target;
		}
	}
	const response = await fetch(CHECKSTYLE_URL);
	if (!response.ok) {
		throw new Error(`Checkstyle download failed: ${response.status}`);
	}
	const bytes = await response.arrayBuffer();
	const actual = digest(bytes);
	if (actual !== CHECKSTYLE_SHA256) {
		throw new Error(`Checkstyle checksum mismatch: ${actual}`);
	}
	await Bun.write(target, bytes);
	return target;
};

const checkstyleJar = async (): Promise<string> => {
	const root = resolve(import.meta.dir, "..", "..");
	const candidates = [
		Bun.env.VIQUI_CHECKSTYLE_JAR,
		join(root, "checkstyle.jar"),
		join(root, ".cache", "checkstyle", CHECKSTYLE_FILE),
	].filter((candidate): candidate is string => Boolean(candidate));
	for (const candidate of candidates) {
		if (await Bun.file(candidate).exists()) {
			return candidate;
		}
	}
	throw new Error(
		`Checkstyle jar not found; run "bun run install:viqui", set VIQUI_CHECKSTYLE_JAR, or download ${CHECKSTYLE_URL}`,
	);
};

export const checkstyleCachePath = (): string =>
	join(resolve(import.meta.dir, "..", ".."), ".cache", "checkstyle", CHECKSTYLE_FILE);

const javaCommand = (): string => {
	if (Bun.env.VIQUI_JAVA) {
		return Bun.env.VIQUI_JAVA;
	}
	return Bun.env.JAVA_HOME ? join(Bun.env.JAVA_HOME, "bin", "java") : "java";
};

type Diagnostic = {
	file: string;
	line: number;
	column: number;
	source: string;
};

const decode = (value: string): string =>
	value
		.replace(/&lt;/g, "<")
		.replace(/&gt;/g, ">")
		.replace(/&quot;/g, '"')
		.replace(/&apos;/g, "'")
		.replace(/&amp;/g, "&");

const parseDiagnostics = (xml: string): Diagnostic[] => {
	const diagnostics: Diagnostic[] = [];
	for (const file of xml.matchAll(/<file name="([^"]*)">([\s\S]*?)<\/file>/g)) {
		const name = decode(file[1]);
		for (const error of file[2].matchAll(
			/<error line="(\d+)" column="(\d+)"[^>]*?source="([^"]*)"\/>/g,
		)) {
			diagnostics.push({
				file: name,
				line: Number(error[1]),
				column: Number(error[2]),
				source: decode(error[3]),
			});
		}
	}
	return diagnostics;
};

export const scanCheckstyle = async (
	config: string,
	categories: string[],
	rule: string,
	message: string,
	paths: string[],
): Promise<Finding[]> => {
	const jar = await checkstyleJar();
	let result: { stdout: Buffer; stderr: Buffer };
	try {
		result = Bun.spawnSync({
			cmd: [javaCommand(), "-jar", jar, "-c", config, "-f", "xml", ...paths],
			stdout: "pipe",
			stderr: "pipe",
		});
	} catch (error) {
		throw new Error(`Checkstyle failed: ${error instanceof Error ? error.message : String(error)}`);
	}
	const stdout = result.stdout.toString();
	if (!stdout.includes("<checkstyle")) {
		throw new Error(`Checkstyle failed: ${result.stderr.toString()}`);
	}
	const diagnostics = parseDiagnostics(stdout);
	const unexpected = diagnostics.filter(
		(item) => !categories.some((category) => item.source.endsWith(category)),
	);
	if (unexpected.length) {
		throw new Error(`Checkstyle returned unexpected diagnostics: ${JSON.stringify(unexpected)}`);
	}
	return diagnostics.map((item) => ({
		rule,
		file: item.file,
		line: item.line,
		column: item.column,
		message,
	}));
};
