import type { Report, SyntaxNode } from "../../../shared/scanner.ts";
import { AST_NODE_TYPES, scanFiles } from "../../../shared/scanner.ts";

const RULE_ID = "no-deep-nesting";
const MESSAGE =
	"Control flow is nested more than three levels; consider extracting a function or using guard clauses.";
const MAX_DEPTH = 3;
const ROOT_DEPTH = 0;
const IGNORED_PROPERTIES = new Set(["loc", "range", "comments", "tokens"]);
const CONTROL_FLOW_TYPES: ReadonlySet<SyntaxNode["type"]> = new Set([
	AST_NODE_TYPES.IfStatement,
	AST_NODE_TYPES.ForStatement,
	AST_NODE_TYPES.ForInStatement,
	AST_NODE_TYPES.ForOfStatement,
	AST_NODE_TYPES.WhileStatement,
	AST_NODE_TYPES.DoWhileStatement,
	AST_NODE_TYPES.SwitchStatement,
	AST_NODE_TYPES.TryStatement,
	AST_NODE_TYPES.WithStatement,
]);
const SCOPE_TYPES: ReadonlySet<SyntaxNode["type"]> = new Set([
	AST_NODE_TYPES.FunctionDeclaration,
	AST_NODE_TYPES.FunctionExpression,
	AST_NODE_TYPES.ArrowFunctionExpression,
	AST_NODE_TYPES.ClassDeclaration,
	AST_NODE_TYPES.ClassExpression,
]);

const walk = (value: unknown, depth: number, report: Report): void => {
	if (!value || typeof value !== "object") {
		return;
	}
	if (Array.isArray(value)) {
		for (const child of value) {
			walk(child, depth, report);
		}
		return;
	}
	if (!("type" in value) || typeof value.type !== "string") {
		return;
	}
	const node = value as SyntaxNode;
	const currentDepth = SCOPE_TYPES.has(node.type)
		? ROOT_DEPTH
		: depth + (CONTROL_FLOW_TYPES.has(node.type) ? 1 : 0);
	if (currentDepth === MAX_DEPTH + 1 && currentDepth > depth) {
		report(node);
	}
	for (const [key, child] of Object.entries(node)) {
		if (!IGNORED_PROPERTIES.has(key)) {
			const isElseIf =
				node.type === AST_NODE_TYPES.IfStatement &&
				key === "alternate" &&
				node.alternate?.type === AST_NODE_TYPES.IfStatement;
			walk(child, isElseIf ? currentDepth - 1 : currentDepth, report);
		}
	}
};

scanFiles(RULE_ID, MESSAGE, (tree, report) => walk(tree, ROOT_DEPTH, report));
