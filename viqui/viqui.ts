#!/usr/bin/env bun
import { realpathSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Command, CommanderError } from "commander";
import { collectFiles } from "./core/files.ts";
import { listRules, scanRules } from "./core/registry.mjs";

const rulesDirectory = join(dirname(fileURLToPath(import.meta.url)), "rules");
const cli = new Command();
cli.name("viqui").description("Run independent code checks").exitOverride();

cli
  .command("list")
  .description("List installed rules as JSON")
  .action(() => {
    process.stdout.write(
      `${JSON.stringify(listRules(rulesDirectory).map(({ manifest }) => manifest.id))}\n`,
    );
  });

cli
  .command("scan")
  .description("Scan files or directories and print findings as JSON")
  .argument("<paths...>", "files or directories to scan")
  .option("--rule <name>", "run one rule")
  .option("--fail-on-findings", "exit with status 1 when findings are present")
  .action(
    (paths: string[], options: { rule?: string; failOnFindings?: boolean }) => {
      const files = paths.flatMap((path) => collectFiles(resolve(path)));
      const findings = scanRules(rulesDirectory, files, options.rule);
      const output = findings.map((finding) => {
        const path = relative(
          realpathSync(process.cwd()),
          realpathSync(finding.file),
        );
        return { ...finding, file: path.startsWith("..") ? path : `./${path}` };
      });
      process.stdout.write(`${JSON.stringify(output)}\n`);
      if (options.failOnFindings && findings.length) {
        process.exitCode = 1;
      }
    },
  );

try {
  cli.parse();
} catch (error) {
  if (error instanceof CommanderError) {
    process.exitCode = error.exitCode === 0 ? 0 : 2;
  } else {
    process.stderr.write(
      `${error instanceof Error ? error.message : String(error)}\n`,
    );
    process.exitCode = 2;
  }
}
