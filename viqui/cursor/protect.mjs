import { protectedOperand } from "../core/protect.mjs";

const input = JSON.parse(await Bun.stdin.text());
const operand = protectedOperand(input.tool_input ?? input);
if (operand !== undefined) {
  await Bun.stdout.write(
    JSON.stringify({
      permission: "deny",
      user_message: `Blocked: "${operand}" contains ".env".`,
      agent_message: `Blocked: "${operand}" contains ".env". Do not read or change environment files.`,
    }),
  );
}
