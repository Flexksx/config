const protectedText = ".env";

const operatedKeys = new Set([
  "command",
  "commands",
  "cmd",
  "dir",
  "directory",
  "file",
  "files",
  "file_path",
  "filepath",
  "filename",
  "glob",
  "patch",
  "path",
  "paths",
]);

const operatedStrings = (value) => {
  const strings = [];
  const visit = (key, node) => {
    if (typeof node === "string") {
      if (operatedKeys.has(key)) {
        strings.push(node);
      }
      return;
    }
    if (Array.isArray(node)) {
      for (const item of node) {
        visit(key, item);
      }
      return;
    }
    if (node !== null && typeof node === "object") {
      for (const [childKey, child] of Object.entries(node)) {
        visit(childKey.toLowerCase(), child);
      }
    }
  };
  visit("", value);
  return strings;
};

export const protectedOperand = (input) =>
  operatedStrings(input).find((value) => value.includes(protectedText));
