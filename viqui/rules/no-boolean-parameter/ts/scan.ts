import type { SyntaxNode } from "../../../shared/scanner.ts";
import { AST_NODE_TYPES, scanFiles, visit } from "../../../shared/scanner.ts";

const RULE_ID = "no-boolean-parameter";
const MESSAGE = "Boolean parameter switches behavior; consider separate operations.";
const FUNCTION_NODE_TYPES = [
	AST_NODE_TYPES.FunctionDeclaration,
	AST_NODE_TYPES.FunctionExpression,
	AST_NODE_TYPES.ArrowFunctionExpression,
	AST_NODE_TYPES.TSEmptyBodyFunctionExpression,
	AST_NODE_TYPES.TSDeclareFunction,
	AST_NODE_TYPES.TSMethodSignature,
	AST_NODE_TYPES.TSCallSignatureDeclaration,
	AST_NODE_TYPES.TSConstructSignatureDeclaration,
	AST_NODE_TYPES.TSFunctionType,
	AST_NODE_TYPES.TSConstructorType,
] as const;

type FunctionNode = Extract<SyntaxNode, { type: (typeof FUNCTION_NODE_TYPES)[number] }>;
const FUNCTION_NODE_TYPE_SET: ReadonlySet<SyntaxNode["type"]> = new Set(FUNCTION_NODE_TYPES);
const isFunctionNode = (node: SyntaxNode): node is FunctionNode =>
	FUNCTION_NODE_TYPE_SET.has(node.type);

const booleanParameter = (parameter: SyntaxNode): boolean => {
	if (parameter.type === AST_NODE_TYPES.TSParameterProperty) {
		return booleanParameter(parameter.parameter);
	}
	const target = parameter.type === AST_NODE_TYPES.AssignmentPattern ? parameter.left : parameter;
	const hasBooleanAnnotation =
		"typeAnnotation" in target &&
		target.typeAnnotation?.type === AST_NODE_TYPES.TSTypeAnnotation &&
		target.typeAnnotation.typeAnnotation.type === AST_NODE_TYPES.TSBooleanKeyword;
	const hasBooleanDefault =
		parameter.type === AST_NODE_TYPES.AssignmentPattern &&
		parameter.right.type === AST_NODE_TYPES.Literal &&
		typeof parameter.right.value === "boolean";
	return hasBooleanAnnotation || hasBooleanDefault;
};

await scanFiles(RULE_ID, MESSAGE, (tree, report) => {
	visit(tree, (node) => {
		if (isFunctionNode(node)) {
			for (const parameter of node.params) {
				if (booleanParameter(parameter)) {
					report(parameter);
				}
			}
		}
	});
});
