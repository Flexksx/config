import { scanFiles } from "../../../shared/scanner.ts";

const RULE_ID = "no-comments";
const MESSAGE = "Comment found; consider expressing the intent in code.";
const directive =
	/^(?:eslint(?:-\w+)*\b|@(?:ts-(?:ignore|expect-error|check|nocheck)|jsx\w*|license|preserve)\b|prettier-ignore\b|biome-ignore\b|istanbul ignore\b|#\s*sourceMappingURL=|\/\s*<reference\b)/;

scanFiles(RULE_ID, MESSAGE, (tree, report) => {
	for (const comment of tree.comments ?? []) {
		if (!directive.test(comment.value.trim())) {
			report(comment);
		}
	}
});
