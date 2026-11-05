import { join } from "node:path";
import { scanCheckstyle } from "../../../shared/checkstyle.ts";

const RULE_ID = "no-thin-wrapper";
const MESSAGE =
	"This wrapper only delegates with preset arguments; consider calling the underlying function directly.";

await Bun.stdout.write(
	JSON.stringify(
		scanCheckstyle(
			join(import.meta.dir, "checkstyle.xml"),
			["thinWrapper"],
			RULE_ID,
			MESSAGE,
			Bun.argv.slice(2),
		),
	),
);
