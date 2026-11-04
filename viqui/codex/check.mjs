import { tmpdir } from "node:os";
import { extname, join, resolve } from "node:path";

const input = JSON.parse(await Bun.stdin.text());
if (
  typeof input.cwd !== "string" ||
  typeof input.tool_input?.command !== "string"
) {
  throw new Error("Expected a tool command and working directory");
}

const git = (...args) =>
  Bun.spawnSync({
    cmd: ["git", ...args],
    cwd: input.cwd,
    stdout: "pipe",
    stderr: "pipe",
  });
const freshPaths = async (paths, cache) => {
  const fresh = [];
  for (const path of paths) {
    const digest = Bun.hash(await Bun.file(path).text()).toString();
    if (cache[path] === digest) {
      continue;
    }
    cache[path] = digest;
    fresh.push(path);
  }
  return fresh;
};
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
  if (!root.success) {
    process.exit(0);
  }
  const repository = root.stdout.toString().trim();
  const changes = [
    git("diff", "--name-only", "-z", "--diff-filter=ACMR"),
    git("diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR"),
    git("ls-files", "--others", "--exclude-standard", "--full-name", "-z"),
  ];
  if (changes.some((result) => !result.success)) {
    throw new Error("Could not list changed files for Viqui");
  }
  const candidates = [
    ...new Set(
      changes.flatMap((result) =>
        result.stdout.toString().split("\0").filter(Boolean),
      ),
    ),
  ]
    .map((path) => resolve(repository, path))
    .filter((path) => supported.has(extname(path)));
  paths = [];
  for (const path of candidates) {
    if (await Bun.file(path).exists()) {
      paths.push(path);
    }
  }
  if (typeof input.session_id === "string") {
    const key = Bun.hash(`${input.session_id}\0${repository}`).toString();
    cachePath = join(tmpdir(), `viqui-hook-${key}.json`);
    if (await Bun.file(cachePath).exists()) {
      cache = await Bun.file(cachePath).json();
    }
    paths = await freshPaths(paths, cache);
  }
} else {
  const candidates = [
    ...input.tool_input.command.matchAll(
      /^\*\*\* (?:Add File|Update File|Move to): (.+)$/gm,
    ),
  ].map((match) => resolve(input.cwd, match[1]));
  paths = [];
  for (const path of candidates) {
    if (await Bun.file(path).exists()) {
      paths.push(path);
    }
  }
}

if (paths.length > 0) {
  const cli = resolve(import.meta.dir, "../viqui.ts");
  const result = Bun.spawnSync({
    cmd: [process.execPath, cli, "scan", ...paths],
    cwd: input.cwd,
    stdout: "pipe",
    stderr: "pipe",
  });
  if (!result.success) {
    throw new Error(`Viqui failed: ${result.stderr.toString()}`);
  }
  const findings = JSON.parse(result.stdout.toString());
  if (cachePath) {
    await Bun.write(cachePath, JSON.stringify(cache));
  }
  if (findings.length > 0) {
    const diagnostics = findings.map(
      (finding) => `${finding.file}:${finding.line}: ${finding.message}`,
    );
    await Bun.stdout.write(
      JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PostToolUse",
          additionalContext: `Review harness findings:\n${diagnostics.join("\n")}`,
        },
      }),
    );
  }
}
