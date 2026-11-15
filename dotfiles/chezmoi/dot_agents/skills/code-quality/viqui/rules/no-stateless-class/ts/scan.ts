import { join } from "node:path";
import { scanBiome } from "../../../shared/biome.ts";

const RULE_ID = "no-stateless-class";
const MESSAGE = "Class or member does not use instance state; consider module functions.";
const config = join(import.meta.dir, "biome-config.json");
await Bun.stdout.write(
	JSON.stringify(
		scanBiome(
			config,
			["lint/style/useThisInClassMethods", "lint/complexity/noStaticOnlyClass"],
			RULE_ID,
			MESSAGE,
			Bun.argv.slice(2),
		),
	),
);
