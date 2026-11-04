#!/usr/bin/env bun
import { realpathSync } from "node:fs";
import { join, relative, resolve } from "node:path";
import { Command, CommanderError } from "commander";
import { collectFiles } from "./core/files.ts";
import { listRules, scanRules } from "./core/registry.mjs";

const rulesDirectory = join(import.meta.dir, "rules");
const cli = new Command();
cli.name("viqui").description("Run independent code checks").exitOverride();

cli
  .command("list")
  .description("List installed rules as JSON")
  .action(async () => {
    const rules = await listRules(rulesDirectory);
    await Bun.stdout.write(
      `${JSON.stringify(rules.map(({ manifest }) => manifest.id))}\n`,
    );
  });

cli
  .command("scan")
  .description("Scan files or directories and print findings as JSON")
  .argument("<paths...>", "files or directories to scan")
  .option("--rule <name>", "run one rule")
  .option("--fail-on-findings", "exit with status 1 when findings are present")
  .action(
    async (
      paths: string[],
      options: { rule?: string; failOnFindings?: boolean },
    ) => {
      const files = (
        await Promise.all(paths.map((path) => collectFiles(resolve(path))))
      ).flat();
      const findings = await scanRules(rulesDirectory, files, options.rule);
      const output = findings.map((finding) => {
        const path = relative(
          realpathSync(process.cwd()),
          realpathSync(finding.file),
        );
        return { ...finding, file: path.startsWith("..") ? path : `./${path}` };
      });
      await Bun.stdout.write(`${JSON.stringify(output)}\n`);
      if (options.failOnFindings && findings.length) {
        process.exitCode = 1;
      }
    },
  );

try {
  await cli.parseAsync(Bun.argv);
} catch (error) {
  if (error instanceof CommanderError) {
    process.exitCode = error.exitCode === 0 ? 0 : 2;
  } else {
    await Bun.stderr.write(
      `${error instanceof Error ? error.message : String(error)}\n`,
    );
    process.exitCode = 2;
  }
}
