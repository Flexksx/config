import ast
import sys
from pathlib import Path

from viqui.core.finding import Finding, write_findings

RULE_ID = "no-nested-ternary"
MESSAGE = "Nested conditional expressions are hard to follow; use separate statements."


def scan(path: Path) -> list[Finding]:
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    nodes = list(ast.walk(tree))
    nested = {
        child
        for node in nodes
        if isinstance(node, ast.IfExp)
        for child in (node.test, node.body, node.orelse)
        if isinstance(child, ast.IfExp)
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
        if isinstance(node, ast.IfExp)
        and node not in nested
        and any(
            isinstance(child, ast.IfExp)
            for child in (node.test, node.body, node.orelse)
        )
    ]


if __name__ == "__main__":
    write_findings(finding for path in sys.argv[1:] for finding in scan(Path(path)))
