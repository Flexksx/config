import ast
import sys
from pathlib import Path

from viqui.core.finding import Finding, write_findings

RULE_ID = "no-long-boolean-chain"
MESSAGE = "Boolean expression has more than three checks; extract named conditions."
MAX_CHECKS = 3


def unwrap(node: ast.AST) -> ast.AST:
    while isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.Not):
        node = node.operand
    return node


def count_checks(value: ast.AST) -> int:
    node = unwrap(value)
    if isinstance(node, ast.BoolOp):
        return sum(count_checks(operand) for operand in node.values)
    if isinstance(node, ast.Compare):
        return len(node.ops)
    return 1


def scan(path: Path) -> list[Finding]:
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    nodes = list(ast.walk(tree))
    nested = {
        unwrap(operand)
        for node in nodes
        if isinstance(node, ast.BoolOp)
        for operand in node.values
    }
    return [
        Finding(
            rule=RULE_ID,
            file=str(path),
            line=node.lineno,
            column=node.col_offset + 1,
            message=MESSAGE,
        )
        for node in nodes
        if isinstance(node, (ast.BoolOp, ast.Compare))
        and node not in nested
        and count_checks(node) > MAX_CHECKS
    ]


if __name__ == "__main__":
    write_findings(finding for path in sys.argv[1:] for finding in scan(Path(path)))
