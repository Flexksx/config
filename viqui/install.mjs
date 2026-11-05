import {
  cpSync,
  mkdirSync,
  mkdtempSync,
  renameSync,
  symlinkSync,
} from "node:fs";
import { homedir } from "node:os";
import { basename, join, resolve } from "node:path";
import { ensureCheckstyleJar } from "./shared/checkstyle.ts";

const source = import.meta.dir;
const repository = resolve(source, "..");
const destination = resolve(
  Bun.argv[2] ?? join(homedir(), ".local/share/viqui"),
);
const releases = join(destination, "releases");
mkdirSync(releases, { recursive: true });
const release = mkdtempSync(join(releases, "release-"));
for (const file of ["package.json", "bun.lock"]) {
  cpSync(join(repository, file), join(release, file));
}
cpSync(source, join(release, "viqui"), {
  recursive: true,
  filter: (path) =>
    ![
      "node_modules",
      ".venv",
      "__pycache__",
      ".pytest_cache",
      ".ruff_cache",
    ].includes(basename(path)),
});
symlinkSync("viqui.ts", join(release, "viqui/viqui"));
const install = Bun.spawnSync({
  cmd: [
    process.execPath,
    "install",
    "--production",
    "--frozen-lockfile",
    "--cache-dir",
    join(repository, ".cache", "bun"),
  ],
  cwd: release,
  stdin: "inherit",
  stdout: "inherit",
  stderr: "inherit",
});
if (!install.success) {
  throw new Error(`Viqui installation failed: ${install.exitCode}`);
}
for (const arguments_ of [
  ["venv", join(release, ".venv")],
  [
    "pip",
    "install",
    "--python",
    join(release, ".venv/bin/python"),
    "ruff==0.17.3",
  ],
]) {
  const result = Bun.spawnSync({
    cmd: ["uv", ...arguments_],
    stdin: "inherit",
    stdout: "inherit",
    stderr: "inherit",
  });
  if (!result.success) {
    throw new Error(`Viqui Ruff installation failed: ${result.exitCode}`);
  }
}
await ensureCheckstyleJar(join(release, "checkstyle.jar"));
const link = join(destination, `current-${basename(release)}`);
symlinkSync(join("releases", basename(release), "viqui"), link);
renameSync(link, join(destination, "current"));
await Bun.stdout.write(`Installed Viqui at ${join(destination, "current")}\n`);
