import ast
import sys
from collections import Counter
from pathlib import Path

from viqui.core.finding import Finding, write_findings

RULE_ID = "no-thin-wrapper"
MESSAGE = (
    "This wrapper only delegates with preset arguments; "
    "consider calling the underlying function directly."
)


def is_delegation(function: ast.FunctionDef) -> bool:
    parameters: ast.arguments = function.args
    has_decorators: bool = bool(function.decorator_list)
    has_defaults: bool = bool(parameters.defaults) or any(parameters.kw_defaults)
    has_variadic_parameters: bool = bool(parameters.vararg or parameters.kwarg)
    has_single_statement: bool = len(function.body) == 1
    has_custom_signature = has_defaults or has_variadic_parameters
    if has_decorators or has_custom_signature:
        return False
    if not has_single_statement or not isinstance(function.body[0], ast.Return):
        return False
    call: ast.expr | None = function.body[0].value
    if not isinstance(call, ast.Call):
        return False
    has_keyword_unpacking: bool = any(keyword.arg is None for keyword in call.keywords)
    if has_keyword_unpacking:
        return False
    arguments: list[ast.expr] = [
        *call.args,
        *(keyword.value for keyword in call.keywords),
    ]
    parameter_names: list[str] = [
        parameter.arg
        for parameter in [
            *parameters.posonlyargs,
            *parameters.args,
            *parameters.kwonlyargs,
        ]
    ]
    forwarded_names: list[str] = [
        argument.id
        for argument in arguments
        if isinstance(argument, ast.Name) and argument.id in parameter_names
    ]
    presets: list[ast.expr] = [
        argument for argument in arguments if isinstance(argument, ast.Constant)
    ]
    has_preset: bool = bool(presets)
    forwards_each_parameter_once: bool = Counter(forwarded_names) == Counter(
        parameter_names
    )
    has_only_forwarded_parameters_and_presets: bool = len(forwarded_names) + len(
        presets
    ) == len(arguments)
    return (
        has_preset
        and forwards_each_parameter_once
        and has_only_forwarded_parameters_and_presets
    )


def enclosing_function(node: ast.AST, parents: dict[ast.AST, ast.AST]) -> ast.AST:
    parent: ast.AST | None = parents.get(node)
    while parent is not None:
        if isinstance(parent, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda)):
            return parent
        parent = parents.get(parent)
    return node


def is_direct_reference(
    reference: ast.Name,
    declaration: ast.FunctionDef,
    scope: ast.AST,
    parents: dict[ast.AST, ast.AST],
) -> bool:
    parent: ast.AST | None = parents.get(reference)
    is_read: bool = isinstance(reference.ctx, ast.Load)
    is_direct_call: bool = isinstance(parent, ast.Call) and parent.func is reference
    is_in_scope: bool = enclosing_function(reference, parents) is scope
    declaration_end: int = declaration.end_lineno or declaration.lineno
    is_recursive: bool = declaration.lineno <= reference.lineno <= declaration_end
    is_local_call = is_direct_call and is_in_scope and not is_recursive
    return is_read and is_local_call


def scan(path: Path) -> list[Finding]:
    tree: ast.Module = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    parents: dict[ast.AST, ast.AST] = {
        child: node for node in ast.walk(tree) for child in ast.iter_child_nodes(node)
    }
    findings: list[Finding] = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.FunctionDef) or not is_delegation(node):
            continue
        parent: ast.AST | None = parents.get(node)
        if not isinstance(parent, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        references: list[ast.Name] = [
            name
            for name in ast.walk(tree)
            if isinstance(name, ast.Name) and name.id == node.name
        ]
        if not references:
            continue
        if not all(
            is_direct_reference(reference, node, parent, parents)
            for reference in references
        ):
            continue
        findings.append(
            Finding(
                rule=RULE_ID,
                file=str(path),
                line=node.lineno,
                column=node.col_offset + 1,
                message=MESSAGE,
            )
        )
    return findings


def main(paths: list[str]) -> None:
    if not paths:
        raise ValueError("Provide at least one Python file to scan")
    write_findings(finding for path in paths for finding in scan(Path(path)))


if __name__ == "__main__":
    main(sys.argv[1:])
