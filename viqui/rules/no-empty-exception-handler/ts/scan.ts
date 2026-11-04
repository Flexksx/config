import { join } from "node:path";
import { scanBiome } from "../../../shared/biome.ts";

const RULE_ID = "no-empty-exception-handler";
const MESSAGE = "Empty block; consider removing it or handling the case explicitly.";
const config = join(import.meta.dir, "biome-config.json");
await Bun.stdout.write(
	JSON.stringify(
		scanBiome(
			config,
			["lint/suspicious/noEmptyBlockStatements"],
			RULE_ID,
			MESSAGE,
			Bun.argv.slice(2),
		),
	),
);
