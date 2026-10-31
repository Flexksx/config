import { spawnSync } from "node:child_process";
import {
  cpSync,
  mkdirSync,
  mkdtempSync,
  renameSync,
  symlinkSync,
} from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const source = dirname(fileURLToPath(import.meta.url));
const repository = resolve(source, "..");
const destination = resolve(
  process.argv[2] ?? join(homedir(), ".local/share/viqui"),
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
const install = spawnSync(
  "bun",
  [
    "install",
    "--production",
    "--frozen-lockfile",
    "--cache-dir",
    join(repository, ".cache", "bun"),
  ],
  {
    cwd: release,
    stdio: "inherit",
  },
);
if (install.error || install.status !== 0) {
  throw new Error(
    `Viqui installation failed: ${install.error?.message ?? install.status}`,
  );
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
  const result = spawnSync("uv", arguments_, { stdio: "inherit" });
  if (result.error || result.status !== 0) {
    throw new Error(
      `Viqui Ruff installation failed: ${result.error?.message ?? result.status}`,
    );
  }
}
const link = join(destination, `current-${basename(release)}`);
symlinkSync(join("releases", basename(release), "viqui"), link);
renameSync(link, join(destination, "current"));
process.stdout.write(`Installed Viqui at ${join(destination, "current")}\n`);
