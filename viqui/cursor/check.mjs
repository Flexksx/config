import { resolve } from "node:path";

const input = JSON.parse(await Bun.stdin.text());
const path = input.tool_input?.file_path ?? input.tool_input?.path;
const cwd = input.cwd ?? input.workspace_roots?.[0];
if (typeof path !== "string" || typeof cwd !== "string") {
  throw new Error("Expected a file path and working directory");
}

const resolved = resolve(cwd, path);
if (await Bun.file(resolved).exists()) {
  const cli = resolve(import.meta.dir, "../viqui.ts");
  const result = Bun.spawnSync({
    cmd: [process.execPath, cli, "scan", resolved],
    cwd,
    stdout: "pipe",
    stderr: "pipe",
  });
  if (!result.success) {
    throw new Error(`Viqui failed: ${result.stderr.toString()}`);
  }
  const findings = JSON.parse(result.stdout.toString());
  if (findings.length > 0) {
    const diagnostics = findings.map(
      (finding) => `${finding.file}:${finding.line}: ${finding.message}`,
    );
    await Bun.stdout.write(
      JSON.stringify({
        additional_context: `Review harness findings:\n${diagnostics.join("\n")}`,
      }),
    );
  }
}
