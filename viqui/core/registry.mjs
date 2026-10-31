import { spawnSync } from "node:child_process";
import { readdirSync, readFileSync } from "node:fs";
import {
  delimiter,
  dirname,
  extname,
  isAbsolute,
  join,
  relative,
  resolve,
} from "node:path";

const validFinding = (finding, rule, paths) => {
  if (!finding) {
    return false;
  }
  if (finding.rule !== rule || !paths.includes(finding.file)) {
    return false;
  }
  const validLine = Number.isInteger(finding.line) && finding.line >= 1;
  const validColumn = Number.isInteger(finding.column) && finding.column >= 1;
  const validMessage =
    typeof finding.message === "string" && Boolean(finding.message);
  return validLine && validColumn && validMessage;
};

export const listRules = (rulesDirectory) => {
  const rules = [];
  const identifiers = new Set();
  for (const entry of readdirSync(rulesDirectory, { withFileTypes: true })) {
    if (!entry.isDirectory()) {
      continue;
    }
    const directory = resolve(rulesDirectory, entry.name);
    const manifest = JSON.parse(
      readFileSync(join(directory, "rule.json"), "utf8"),
    );
    const invalidIdentifier =
      typeof manifest.id !== "string" ||
      !manifest.id ||
      identifiers.has(manifest.id);
    const invalidScanners =
      !Array.isArray(manifest.scanners) || !manifest.scanners.length;
    if (invalidIdentifier || invalidScanners) {
      throw new Error(`Invalid rule manifest: ${directory}`);
    }
    identifiers.add(manifest.id);
    rules.push({ directory, manifest });
  }
  return rules;
};

export const scanRules = (rulesDirectory, files, selectedRule) => {
  const findings = [];
  const rules = listRules(rulesDirectory);
  if (
    selectedRule &&
    !rules.some(({ manifest }) => manifest.id === selectedRule)
  ) {
    throw new Error(`Unknown rule: ${selectedRule}`);
  }
  for (const { directory, manifest } of rules) {
    if (selectedRule && manifest.id !== selectedRule) {
      continue;
    }
    for (const scanner of manifest.scanners) {
      const invalidExtensions =
        !Array.isArray(scanner.extensions) ||
        !scanner.extensions.length ||
        !scanner.extensions.every(
          (extension) =>
            typeof extension === "string" && /^\.[a-z0-9]+$/.test(extension),
        );
      const invalidRuntime = !["node", "python3"].includes(scanner.runtime);
      const invalidEntrypoint =
        typeof scanner.entrypoint !== "string" ||
        isAbsolute(scanner.entrypoint);
      const invalidScanner = invalidRuntime || invalidEntrypoint;
      if (invalidExtensions || invalidScanner) {
        throw new Error(`Invalid scanner in rule: ${manifest.id}`);
      }
      const script = resolve(directory, scanner.entrypoint);
      const scriptPath = relative(directory, script);
      const outsideRule = scriptPath.startsWith("..") || isAbsolute(scriptPath);
      if (!scriptPath || outsideRule) {
        throw new Error(`Invalid entrypoint in rule: ${manifest.id}`);
      }
      const paths = [
        ...new Set(
          files.filter((file) => scanner.extensions.includes(extname(file))),
        ),
      ];
      if (!paths.length) {
        continue;
      }
      const result = spawnSync(scanner.runtime, [script, ...paths], {
        encoding: "utf8",
        env:
          scanner.runtime === "python3"
            ? {
                ...process.env,
                PYTHONPATH: [
                  dirname(dirname(rulesDirectory)),
                  process.env.PYTHONPATH,
                ]
                  .filter(Boolean)
                  .join(delimiter),
              }
            : process.env,
      });
      if (result.error || result.status !== 0) {
        throw new Error(
          `Rule ${manifest.id} failed: ${result.error?.message ?? result.stderr}`,
        );
      }
      const output = JSON.parse(result.stdout);
      if (!Array.isArray(output)) {
        throw new Error(`Invalid findings from rule: ${manifest.id}`);
      }
      if (
        !output.every((finding) => validFinding(finding, manifest.id, paths))
      ) {
        throw new Error(`Invalid finding from rule: ${manifest.id}`);
      }
      findings.push(...output);
    }
  }
  return findings;
};
