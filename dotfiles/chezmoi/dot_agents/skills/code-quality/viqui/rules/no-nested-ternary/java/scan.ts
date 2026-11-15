import { join } from "node:path";
import { scanCheckstyle } from "../../../shared/checkstyle.ts";

const RULE_ID = "no-nested-ternary";
const MESSAGE = "Nested conditional expressions are hard to follow; use separate statements.";

await Bun.stdout.write(
	JSON.stringify(
		await scanCheckstyle(
			join(import.meta.dir, "checkstyle.xml"),
			["nestedTernary"],
			RULE_ID,
			MESSAGE,
			Bun.argv.slice(2),
		),
	),
);
