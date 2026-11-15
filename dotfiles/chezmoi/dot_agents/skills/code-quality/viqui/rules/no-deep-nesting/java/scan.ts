import { join } from "node:path";
import { scanCheckstyle } from "../../../shared/checkstyle.ts";

const RULE_ID = "no-deep-nesting";
const MESSAGE =
	"Control flow is nested more than three levels; consider extracting a function or using guard clauses.";

await Bun.stdout.write(
	JSON.stringify(
		await scanCheckstyle(
			join(import.meta.dir, "checkstyle.xml"),
			["deepNesting"],
			RULE_ID,
			MESSAGE,
			Bun.argv.slice(2),
		),
	),
);
