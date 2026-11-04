import { join, resolve } from "node:path";

const ignoredDirectories = new Set([
  ".git",
  ".venv",
  "node_modules",
  "__pycache__",
]);

const isIgnored = (path: string): boolean =>
  path.split("/").some((segment) => ignoredDirectories.has(segment));

export const collectFiles = async (path: string): Promise<string[]> => {
  const absolute = resolve(path);
  if (await Bun.file(absolute).exists()) {
    return [absolute];
  }
  const files: string[] = [];
  const glob = new Bun.Glob("**/*");
  for await (const relativePath of glob.scan({
    cwd: absolute,
    dot: true,
    onlyFiles: true,
  })) {
    if (!isIgnored(relativePath)) {
      files.push(join(absolute, relativePath));
    }
  }
  return files;
};
