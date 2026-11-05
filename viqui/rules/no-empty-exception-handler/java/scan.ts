import { join } from "node:path";
import { scanCheckstyle } from "../../../shared/checkstyle.ts";

const RULE_ID = "no-empty-exception-handler";
const MESSAGE = "Empty block; consider removing it or handling the case explicitly.";

await Bun.stdout.write(
	JSON.stringify(
		await scanCheckstyle(
			join(import.meta.dir, "checkstyle.xml"),
			["EmptyBlockCheck", "EmptyCatchBlockCheck"],
			RULE_ID,
			MESSAGE,
			Bun.argv.slice(2),
		),
	),
);
