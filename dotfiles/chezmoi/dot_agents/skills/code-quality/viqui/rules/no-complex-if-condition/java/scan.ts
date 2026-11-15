import { join } from "node:path";
import { scanCheckstyle } from "../../../shared/checkstyle.ts";

const RULE_ID = "no-complex-if-condition";
const MESSAGE =
	"This if condition has more than two boolean expressions; consider extracting a named condition.";

await Bun.stdout.write(
	JSON.stringify(
		await scanCheckstyle(
			join(import.meta.dir, "checkstyle.xml"),
			["complexIfCondition"],
			RULE_ID,
			MESSAGE,
			Bun.argv.slice(2),
		),
	),
);
