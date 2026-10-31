import { fileURLToPath } from "node:url";
import { scanBiome } from "../../../shared/biome.ts";

const RULE_ID = "no-empty-exception-handler";
const MESSAGE = "Empty block; consider removing it or handling the case explicitly.";
const config = fileURLToPath(new URL("./biome-config.json", import.meta.url));
process.stdout.write(
	JSON.stringify(
		scanBiome(
			config,
			["lint/suspicious/noEmptyBlockStatements"],
			RULE_ID,
			MESSAGE,
			process.argv.slice(2),
		),
	),
);
