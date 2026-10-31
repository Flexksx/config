import { readFileSync } from "node:fs";
import parser from "@typescript-eslint/parser";
import type { TSESTree } from "@typescript-eslint/utils";
import type { Finding } from "../core/finding.ts";

export { AST_NODE_TYPES } from "@typescript-eslint/types";

const NON_NODE_PROPERTIES = new Set(["loc", "range", "comments", "tokens"]);
const FILE_ENCODING = "utf8";
const TSX_EXTENSION = ".tsx";

export type SyntaxNode = TSESTree.Node;
export type Report = (node: { loc: TSESTree.SourceLocation }) => void;
export type Analysis = {
	parents: Map<SyntaxNode, SyntaxNode>;
	scopeManager: ReturnType<typeof parser.parseForESLint>["scopeManager"];
};

const parentNodes = (tree: SyntaxNode): Map<SyntaxNode, SyntaxNode> => {
	const parents = new Map<SyntaxNode, SyntaxNode>();
	visit(tree, (node) => {
		for (const [key, value] of Object.entries(node)) {
			if (NON_NODE_PROPERTIES.has(key)) {
				continue;
			}
			for (const child of Array.isArray(value) ? value : [value]) {
				if (!child || typeof child !== "object") {
					continue;
				}
				if ("type" in child) {
					parents.set(child as SyntaxNode, node);
				}
			}
		}
	});
	return parents;
};

export const visit = (node: unknown, callback: (node: SyntaxNode) => void): void => {
	if (!node || typeof node !== "object") {
		return;
	}
	if (Array.isArray(node)) {
		for (const item of node) {
			visit(item, callback);
		}
		return;
	}
	if ("type" in node && typeof node.type === "string") {
		callback(node as SyntaxNode);
	}
	for (const [key, value] of Object.entries(node)) {
		if (!NON_NODE_PROPERTIES.has(key)) {
			visit(value, callback);
		}
	}
};

export const scanFiles = (
	rule: string,
	message: string,
	inspect: (tree: TSESTree.Program, report: Report, file: string, analysis: Analysis) => void,
): void => {
	const findings: Finding[] = [];
	for (const file of process.argv.slice(2)) {
		const parsed = parser.parseForESLint(readFileSync(file, FILE_ENCODING), {
			loc: true,
			range: true,
			comment: true,
			jsx: file.endsWith(TSX_EXTENSION) || file.endsWith(".jsx"),
		});
		const tree = parsed.ast;
		const report: Report = (node) =>
			findings.push({
				rule,
				file,
				line: node.loc.start.line,
				column: node.loc.start.column + 1,
				message,
			});
		let parents: Map<SyntaxNode, SyntaxNode> | undefined;
		inspect(tree, report, file, {
			get parents() {
				if (!parents) {
					parents = parentNodes(tree);
				}
				return parents;
			},
			scopeManager: parsed.scopeManager,
		});
	}
	process.stdout.write(JSON.stringify(findings));
};
