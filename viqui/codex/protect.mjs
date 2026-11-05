import { protectedOperand } from "../core/protect.mjs";

const input = JSON.parse(await Bun.stdin.text());
const operand = protectedOperand(input.tool_input ?? input);
if (operand !== undefined) {
  await Bun.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: `Blocked: "${operand}" contains ".env".`,
      },
    }),
  );
}
