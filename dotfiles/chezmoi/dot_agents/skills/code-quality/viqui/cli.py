import argparse
import json
import os
import sys
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
if str(SKILL_ROOT) not in sys.path:
    sys.path.insert(0, str(SKILL_ROOT))

from viqui.dispatch import DispatchError, list_rules, scan_rules
from viqui.files import collect_files


def _display_path(path: str) -> str:
    relative = os.path.relpath(
        os.path.realpath(path), os.path.realpath(os.getcwd())
    )
    return relative if relative.startswith("..") else f"./{relative}"


def _run(args: argparse.Namespace) -> int:
    if args.command == "list":
        identifiers = [rule["manifest"]["id"] for rule in list_rules()]
        print(json.dumps(identifiers))
        return 0

    files = []
    for path in args.paths:
        files.extend(collect_files(path))
    findings, skips = scan_rules(files, args.rule)
    for skip in skips:
        print(
            f"code-quality: skipped {skip.rule} ({skip.language}): {skip.reason}",
            file=sys.stderr,
        )
    output = [{**finding, "file": _display_path(finding["file"])} for finding in findings]
    print(json.dumps(output))
    if args.fail_on_findings and findings:
        return 1
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="code-quality")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("list", help="list installed rule ids as JSON")

    check = subparsers.add_parser(
        "check", help="scan files or directories and print findings as JSON"
    )
    check.add_argument("paths", nargs="+")
    check.add_argument("--rule", help="run one rule")
    check.add_argument("--fail-on-findings", action="store_true")

    args = parser.parse_args(argv)
    try:
        return _run(args)
    except DispatchError as error:
        print(str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
