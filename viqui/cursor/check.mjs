import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const input = JSON.parse(readFileSync(0, "utf8"));
const path = input.tool_input?.file_path ?? input.tool_input?.path;
const cwd = input.cwd ?? input.workspace_roots?.[0];
if (typeof path !== "string" || typeof cwd !== "string") {
  throw new Error("Expected a file path and working directory");
}

const resolved = resolve(cwd, path);
if (existsSync(resolved)) {
  const cli = resolve(dirname(fileURLToPath(import.meta.url)), "../viqui.ts");
  const result = spawnSync("bun", [cli, "scan", resolved], {
    encoding: "utf8",
    cwd,
  });
  if (result.error || result.status !== 0) {
    throw new Error(`Viqui failed: ${result.error?.message ?? result.stderr}`);
  }
  const findings = JSON.parse(result.stdout);
  if (findings.length > 0) {
    const diagnostics = findings.map(
      (finding) => `${finding.file}:${finding.line}: ${finding.message}`,
    );
    process.stdout.write(
      JSON.stringify({
        additional_context: `Review harness findings:\n${diagnostics.join("\n")}`,
      }),
    );
  }
}
