import { join } from "node:path";
import { scanCheckstyle } from "../../../shared/checkstyle.ts";

const RULE_ID = "no-boolean-parameter";
const MESSAGE = "Boolean parameter switches behavior; consider separate operations.";

await Bun.stdout.write(
	JSON.stringify(
		scanCheckstyle(
			join(import.meta.dir, "checkstyle.xml"),
			["booleanParameter"],
			RULE_ID,
			MESSAGE,
			Bun.argv.slice(2),
		),
	),
);
