import { join } from "node:path";
import { scanCheckstyle } from "../../../shared/checkstyle.ts";

const RULE_ID = "no-comments";
const MESSAGE = "Comment found; consider expressing the intent in code.";
const DIRECTIVE =
	/^(?:\/\/\s*(?:noinspection\b|NOSONAR\b|CHECKSTYLE:|SUPPRESS\s+CHECKSTYLE|spotless:|region\b|endregion\b|@formatter:)|(?:\/\*\*?)\s*(?:@license\b|Copyright\b))/;

const findings = scanCheckstyle(
	join(import.meta.dir, "checkstyle.xml"),
	["IllegalTokenCheck"],
	RULE_ID,
	MESSAGE,
	Bun.argv.slice(2),
);

const lines = new Map<string, string[]>();
const kept = [];
for (const finding of findings) {
	let fileLines = lines.get(finding.file);
	if (!fileLines) {
		fileLines = (await Bun.file(finding.file).text()).split("\n");
		lines.set(finding.file, fileLines);
	}
	const comment = (fileLines[finding.line - 1] ?? "").slice(finding.column - 1);
	if (!DIRECTIVE.test(comment)) {
		kept.push(finding);
	}
}

await Bun.stdout.write(JSON.stringify(kept));
