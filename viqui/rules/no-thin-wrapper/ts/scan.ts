import type { TSESTree } from "@typescript-eslint/utils";
import { AST_NODE_TYPES, scanFiles, visit } from "../../../shared/scanner.ts";

const RULE_ID = "no-thin-wrapper";
const MESSAGE =
	"This wrapper only delegates with preset arguments; consider calling the underlying function directly.";
const CONSTANT_DECLARATION_KIND = "const";
type FunctionNode =
	| TSESTree.FunctionDeclaration
	| TSESTree.FunctionExpression
	| TSESTree.ArrowFunctionExpression;

const delegation = (fn: FunctionNode) => {
	const unsupportedFunction = fn.async || fn.generator;
	if (unsupportedFunction || fn.params.some((param) => param.type !== AST_NODE_TYPES.Identifier)) {
		return;
	}
	let body: TSESTree.Expression | TSESTree.BlockStatement | null = fn.body;
	if (body.type === AST_NODE_TYPES.BlockStatement) {
		if (body.body.length !== 1 || body.body[0].type !== AST_NODE_TYPES.ReturnStatement) {
			return;
		}
		body = body.body[0].argument;
	}
	if (body?.type !== AST_NODE_TYPES.CallExpression) {
		return;
	}
	if (body.optional || body.arguments.length === 0) {
		return;
	}
	const parameters = fn.params
		.filter((param): param is TSESTree.Identifier => param.type === AST_NODE_TYPES.Identifier)
		.map((param) => param.name);
	const forwarded = body.arguments.filter(
		(arg): arg is TSESTree.Identifier =>
			arg.type === AST_NODE_TYPES.Identifier && parameters.includes(arg.name),
	);
	const presets = body.arguments.filter((arg) => arg.type === AST_NODE_TYPES.Literal);
	const hasPreset = presets.length > 0;
	const forwardsEveryParameter = forwarded.length === parameters.length;
	const forwardsEachParameterOnce =
		new Set(forwarded.map((arg) => arg.name)).size === parameters.length;
	const hasOnlyForwardedParametersAndPresets =
		forwarded.length + presets.length === body.arguments.length;
	const forwardsParametersExactlyOnce = forwardsEveryParameter && forwardsEachParameterOnce;
	const validArguments = hasPreset && hasOnlyForwardedParametersAndPresets;
	if (!forwardsParametersExactlyOnce || !validArguments) {
		return;
	}
	return body;
};

scanFiles(RULE_ID, MESSAGE, (tree, report, _file, analysis) => {
	visit(tree, (node) => {
		let declaration: TSESTree.VariableDeclarator | TSESTree.FunctionDeclaration;
		let name: TSESTree.BindingName | null;
		let fn: FunctionNode;
		if (node.type === AST_NODE_TYPES.FunctionDeclaration) {
			declaration = node;
			name = node.id;
			fn = node;
		} else if (node.type === AST_NODE_TYPES.VariableDeclarator) {
			const parent = analysis.parents.get(node);
			const initializer = node.init;
			const isFunction =
				initializer?.type === AST_NODE_TYPES.ArrowFunctionExpression ||
				initializer?.type === AST_NODE_TYPES.FunctionExpression;
			if (parent?.type !== AST_NODE_TYPES.VariableDeclaration) {
				return;
			}
			if (parent.kind !== CONSTANT_DECLARATION_KIND || !isFunction) {
				return;
			}
			declaration = node;
			name = node.id;
			fn = initializer;
		} else {
			return;
		}
		if (name?.type !== AST_NODE_TYPES.Identifier || !delegation(fn)) {
			return;
		}
		let ancestor = analysis.parents.get(declaration);
		while (ancestor) {
			if (
				ancestor.type === AST_NODE_TYPES.ExportNamedDeclaration ||
				ancestor.type === AST_NODE_TYPES.ExportDefaultDeclaration
			) {
				return;
			}
			ancestor = analysis.parents.get(ancestor);
		}
		const variable = analysis.scopeManager
			.getDeclaredVariables(declaration)
			.find((item) => item.name === name.name);
		const references = variable?.references.filter((reference) => !reference.init) ?? [];
		if (!references.length) {
			return;
		}
		const allDirectCalls = references.every((reference) => {
			const identifier = reference.identifier;
			const parent = analysis.parents.get(identifier);
			const isReadOnly = reference.isRead() && !reference.isWrite();
			const isDirectCall =
				parent?.type === AST_NODE_TYPES.CallExpression && parent.callee === identifier;
			const isInsideDeclaration =
				identifier.range[0] >= declaration.range[0] && identifier.range[1] <= declaration.range[1];
			return isReadOnly && isDirectCall && !isInsideDeclaration;
		});
		if (allDirectCalls) {
			report(name);
		}
	});
});
