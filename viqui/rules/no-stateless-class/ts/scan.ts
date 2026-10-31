import { fileURLToPath } from "node:url";
import { scanBiome } from "../../../shared/biome.ts";

const RULE_ID = "no-stateless-class";
const MESSAGE = "Class or member does not use instance state; consider module functions.";
const config = fileURLToPath(new URL("./biome-config.json", import.meta.url));
process.stdout.write(
	JSON.stringify(
		scanBiome(
			config,
			["lint/style/useThisInClassMethods", "lint/complexity/noStaticOnlyClass"],
			RULE_ID,
			MESSAGE,
			process.argv.slice(2),
		),
	),
);
