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

const runScanner = (rule, runtime, script, paths, env) => {
  const command = runtime === "bun" ? process.execPath : runtime;
  let result;
  try {
    result = Bun.spawnSync({
      cmd: [command, script, ...paths],
      env,
      stdout: "pipe",
      stderr: "pipe",
    });
  } catch (error) {
    throw new Error(
      `Rule ${rule} failed: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
  if (!result.success) {
    throw new Error(`Rule ${rule} failed: ${result.stderr.toString()}`);
  }
  return result;
};

export const listRules = async (rulesDirectory) => {
  const rules = [];
  const identifiers = new Set();
  const glob = new Bun.Glob("*");
  for await (const entry of glob.scan({
    cwd: rulesDirectory,
    onlyFiles: false,
  })) {
    const directory = resolve(rulesDirectory, entry);
    if (await Bun.file(directory).exists()) {
      continue;
    }
    const manifestPath = join(directory, "rule.json");
    if (!(await Bun.file(manifestPath).exists())) {
      throw new Error(`Invalid rule manifest: ${directory}`);
    }
    const manifest = await Bun.file(manifestPath).json();
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

export const scanRules = async (rulesDirectory, files, selectedRule) => {
  const findings = [];
  const rules = await listRules(rulesDirectory);
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
      const invalidRuntime = !["bun", "python3"].includes(scanner.runtime);
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
      const env =
        scanner.runtime === "python3"
          ? {
              ...Bun.env,
              PYTHONPATH: [dirname(dirname(rulesDirectory)), Bun.env.PYTHONPATH]
                .filter(Boolean)
                .join(delimiter),
            }
          : Bun.env;
      const result = runScanner(
        manifest.id,
        scanner.runtime,
        script,
        paths,
        env,
      );
      const output = JSON.parse(result.stdout.toString());
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
