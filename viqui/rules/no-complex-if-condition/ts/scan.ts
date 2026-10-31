import type { SyntaxNode } from "../../../shared/scanner.ts";
import { AST_NODE_TYPES, scanFiles, visit } from "../../../shared/scanner.ts";

const RULE_ID = "no-complex-if-condition";
const MESSAGE =
	"This if condition has more than two checks; consider extracting a named condition.";
const MAX_CONDITIONS = 2;
const BOOLEAN_OPERATORS = new Set(["&&", "||"]);
const NOT_OPERATOR = "!";

const countConditions = (node: SyntaxNode): number => {
	if (node.type === AST_NODE_TYPES.LogicalExpression && BOOLEAN_OPERATORS.has(node.operator)) {
		return countConditions(node.left) + countConditions(node.right);
	}
	if (node.type === AST_NODE_TYPES.UnaryExpression && node.operator === NOT_OPERATOR) {
		return countConditions(node.argument);
	}
	return 1;
};

scanFiles(RULE_ID, MESSAGE, (tree, report) => {
	visit(tree, (node) => {
		if (node.type === AST_NODE_TYPES.IfStatement && countConditions(node.test) > MAX_CONDITIONS) {
			report(node);
		}
	});
});
