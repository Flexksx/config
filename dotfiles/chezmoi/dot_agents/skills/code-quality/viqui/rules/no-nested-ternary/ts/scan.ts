import { join } from "node:path";
import { scanBiome } from "../../../shared/biome.ts";

const RULE_ID = "no-nested-ternary";
const MESSAGE = "Nested conditional expressions are hard to follow; use separate statements.";
const config = join(import.meta.dir, "biome-config.json");
await Bun.stdout.write(
	JSON.stringify(
		scanBiome(config, ["lint/style/noNestedTernary"], RULE_ID, MESSAGE, Bun.argv.slice(2)),
	),
);
