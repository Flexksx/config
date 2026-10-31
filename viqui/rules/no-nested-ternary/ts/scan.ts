import { fileURLToPath } from "node:url";
import { scanBiome } from "../../../shared/biome.ts";

const RULE_ID = "no-nested-ternary";
const MESSAGE = "Nested conditional expressions are hard to follow; use separate statements.";
const config = fileURLToPath(new URL("./biome-config.json", import.meta.url));
process.stdout.write(
	JSON.stringify(
		scanBiome(config, ["lint/style/noNestedTernary"], RULE_ID, MESSAGE, process.argv.slice(2)),
	),
);
