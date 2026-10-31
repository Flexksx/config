import { readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const ignoredDirectories = new Set([
  ".git",
  ".venv",
  "node_modules",
  "__pycache__",
]);

export const collectFiles = (path: string): string[] => {
  const stat = statSync(path);
  if (stat.isFile()) {
    return [path];
  }
  if (!stat.isDirectory()) {
    return [];
  }
  return readdirSync(path, { withFileTypes: true })
    .filter((entry) => !entry.isSymbolicLink())
    .filter(
      (entry) => !entry.isDirectory() || !ignoredDirectories.has(entry.name),
    )
    .flatMap((entry) => collectFiles(join(path, entry.name)));
};
