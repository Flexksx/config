import { join } from "node:path";
import { scanCheckstyle } from "../../../shared/checkstyle.ts";

const RULE_ID = "no-long-boolean-chain";
const MESSAGE = "Boolean expression has more than three checks; extract named conditions.";

await Bun.stdout.write(
	JSON.stringify(
		scanCheckstyle(
			join(import.meta.dir, "checkstyle.xml"),
			["BooleanExpressionComplexityCheck"],
			RULE_ID,
			MESSAGE,
			Bun.argv.slice(2),
		),
	),
);
