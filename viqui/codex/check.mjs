import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const input = JSON.parse(readFileSync(0, "utf8"));
if (
  typeof input.cwd !== "string" ||
  typeof input.tool_input?.command !== "string"
) {
  throw new Error("Expected a tool command and working directory");
}

const git = (...args) =>
  spawnSync("git", args, { cwd: input.cwd, encoding: "utf8" });
const supported = new Set([
  ".py",
  ".js",
  ".jsx",
  ".mjs",
  ".cjs",
  ".ts",
  ".tsx",
]);
let paths;
let cachePath;
let cache = {};
if (input.tool_name === "Bash") {
  const root = git("rev-parse", "--show-toplevel");
  if (root.status !== 0) {
    process.exit(0);
  }
  const repository = root.stdout.trim();
  const changes = [
    git("diff", "--name-only", "-z", "--diff-filter=ACMR"),
    git("diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR"),
    git("ls-files", "--others", "--exclude-standard", "-z"),
  ];
  if (changes.some((result) => result.status !== 0)) {
    throw new Error("Could not list changed files for Viqui");
  }
  paths = [
    ...new Set(
      changes.flatMap((result) => result.stdout.split("\0").filter(Boolean)),
    ),
  ]
    .map((path) => resolve(repository, path))
    .filter(
      (path) =>
        supported.has(extname(path)) &&
        existsSync(path) &&
        statSync(path).isFile(),
    );
  if (typeof input.session_id === "string") {
    const key = createHash("sha256")
      .update(`${input.session_id}\0${repository}`)
      .digest("hex");
    cachePath = join(tmpdir(), `viqui-hook-${key}.json`);
    if (existsSync(cachePath)) {
      cache = JSON.parse(readFileSync(cachePath, "utf8"));
    }
    paths = paths.filter((path) => {
      const digest = createHash("sha256")
        .update(readFileSync(path))
        .digest("hex");
      if (cache[path] === digest) {
        return false;
      }
      cache[path] = digest;
      return true;
    });
  }
} else {
  paths = [
    ...input.tool_input.command.matchAll(
      /^\*\*\* (?:Add File|Update File|Move to): (.+)$/gm,
    ),
  ]
    .map((match) => resolve(input.cwd, match[1]))
    .filter((path) => existsSync(path));
}

if (paths.length > 0) {
  const cli = resolve(dirname(fileURLToPath(import.meta.url)), "../viqui.ts");
  const result = spawnSync("bun", [cli, "scan", ...paths], {
    encoding: "utf8",
    cwd: input.cwd,
  });
  if (result.error || result.status !== 0) {
    throw new Error(`Viqui failed: ${result.error?.message ?? result.stderr}`);
  }
  const findings = JSON.parse(result.stdout);
  if (cachePath) {
    writeFileSync(cachePath, JSON.stringify(cache));
  }
  if (findings.length > 0) {
    const diagnostics = findings.map(
      (finding) => `${finding.file}:${finding.line}: ${finding.message}`,
    );
    process.stdout.write(
      JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PostToolUse",
          additionalContext: `Review harness findings:\n${diagnostics.join("\n")}`,
        },
      }),
    );
  }
}
