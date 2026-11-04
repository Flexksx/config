import { expect, test } from "bun:test";
import {
  formatFindings,
  supportedPath,
} from "../../dotfiles/chezmoi/dot_pi/agent/extensions/viqui/index.ts";

test("recognizes scannable file extensions", () => {
  expect(supportedPath("example.ts")).toBe(true);
  expect(supportedPath("example.tsx")).toBe(true);
  expect(supportedPath("example.py")).toBe(true);
  expect(supportedPath("example.mjs")).toBe(true);
  expect(supportedPath("example.md")).toBe(false);
  expect(supportedPath("example")).toBe(false);
});

test("formats findings as harness feedback", () => {
  expect(
    formatFindings([
      { file: "./a.ts", line: 3, message: "Comment found." },
      { file: "./b.py", line: 7, message: "Wrapper found." },
    ]),
  ).toBe(
    "Review harness findings:\n./a.ts:3: Comment found.\n./b.py:7: Wrapper found.",
  );
});
