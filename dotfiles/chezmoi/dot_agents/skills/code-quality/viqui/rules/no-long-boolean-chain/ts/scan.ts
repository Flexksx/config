import type { SyntaxNode } from "../../../shared/scanner.ts";
import { AST_NODE_TYPES, scanFiles, visit } from "../../../shared/scanner.ts";

const RULE_ID = "no-long-boolean-chain";
const MESSAGE = "Boolean expression has more than three checks; extract named conditions.";
const MAX_CHECKS = 3;

type Logical = Extract<SyntaxNode, { type: typeof AST_NODE_TYPES.LogicalExpression }>;

const unwrap = (node: SyntaxNode): SyntaxNode => {
	if (node.type === AST_NODE_TYPES.UnaryExpression && node.operator === "!") {
		return unwrap(node.argument);
	}
	return node;
};

const isBooleanChain = (node: SyntaxNode): node is Logical =>
	node.type === AST_NODE_TYPES.LogicalExpression &&
	(node.operator === "&&" || node.operator === "||");

const countChecks = (value: SyntaxNode): number => {
	const node = unwrap(value);
	if (isBooleanChain(node)) {
		return countChecks(node.left) + countChecks(node.right);
	}
	return 1;
};

await scanFiles(RULE_ID, MESSAGE, (tree, report) => {
	const chains: Logical[] = [];
	const nested = new Set<SyntaxNode>();
	visit(tree, (node) => {
		if (!isBooleanChain(node)) {
			return;
		}
		chains.push(node);
		for (const operand of [node.left, node.right]) {
			const child = unwrap(operand);
			if (isBooleanChain(child)) {
				nested.add(child);
			}
		}
	});
	for (const chain of chains) {
		if (!nested.has(chain) && countChecks(chain) > MAX_CHECKS) {
			report(chain);
		}
	}
});
