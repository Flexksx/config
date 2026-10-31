import ast
import sys
from pathlib import Path

from viqui.core.finding import Finding, write_findings

RULE_ID = "no-stateless-class"
MESSAGE = "This class has no visible instance state; consider module functions."


def is_stateless(node: ast.ClassDef) -> bool:
    has_inheritance = bool(node.bases or node.keywords)
    if has_inheritance or node.decorator_list:
        return False
    methods = [
        item
        for item in node.body
        if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef))
    ]
    if not methods or any(
        method.name.startswith("__") or method.decorator_list for method in methods
    ):
        return False
    if any(isinstance(item, (ast.Assign, ast.AnnAssign)) for item in node.body):
        return False
    names = {method.name for method in methods}
    for method in methods:
        parameters = [*method.args.posonlyargs, *method.args.args]
        if not parameters:
            return False
        receiver = parameters[0].arg
        parents = {
            child: parent
            for parent in ast.walk(method)
            for child in ast.iter_child_nodes(parent)
        }
        for item in ast.walk(method):
            if not isinstance(item, ast.Name) or item.id != receiver:
                continue
            attribute = parents.get(item)
            call = parents.get(attribute)
            is_method_access = (
                isinstance(attribute, ast.Attribute)
                and attribute.value is item
                and attribute.attr in names
            )
            is_method_call = isinstance(call, ast.Call) and call.func is attribute
            if not (is_method_access and is_method_call):
                return False
    return True


def scan(path: Path) -> list[Finding]:
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    return [
        Finding(
            rule=RULE_ID,
            file=str(path),
            line=node.lineno,
            column=node.col_offset + 1,
            message=MESSAGE,
        )
        for node in ast.walk(tree)
        if isinstance(node, ast.ClassDef) and is_stateless(node)
    ]


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise ValueError("Provide at least one Python file to scan")
    write_findings(finding for path in sys.argv[1:] for finding in scan(Path(path)))
