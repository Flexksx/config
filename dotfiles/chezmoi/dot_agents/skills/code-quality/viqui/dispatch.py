import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

RUFF_UNAVAILABLE = "ruff not available"
CHECKSTYLE_MARKERS = ("Checkstyle jar not found", "Checkstyle failed")

SKILL_ROOT = Path(__file__).resolve().parents[1]
RULES_DIR = SKILL_ROOT / "viqui" / "rules"

EXTENSION_PATTERN = re.compile(r"^\.[a-z0-9]+$")


class DispatchError(Exception):
    pass


class Skipped(Exception):
    def __init__(self, rule: str, language: str, reason: str):
        super().__init__(reason)
        self.rule = rule
        self.language = language
        self.reason = reason


def _valid_positive_integer(value: object) -> bool:
    return isinstance(value, int) and value >= 1


def _valid_finding(finding: object, rule: str, paths: set[str]) -> bool:
    if not isinstance(finding, dict):
        return False
    if finding.get("rule") != rule:
        return False
    if finding.get("file") not in paths:
        return False
    if not _valid_positive_integer(finding.get("line")):
        return False
    if not _valid_positive_integer(finding.get("column")):
        return False
    message = finding.get("message")
    return isinstance(message, str) and bool(message)


def list_rules(rules_dir: Path = RULES_DIR) -> list[dict]:
    rules = []
    identifiers: set[str] = set()
    for directory in sorted(rules_dir.iterdir()):
        if not directory.is_dir():
            continue
        manifest_path = directory / "rule.json"
        if not manifest_path.is_file():
            raise DispatchError(f"Invalid rule manifest: {directory}")
        manifest = json.loads(manifest_path.read_text())
        identifier = manifest.get("id")
        scanners = manifest.get("scanners")
        invalid_identifier = (
            not isinstance(identifier, str)
            or not identifier
            or identifier in identifiers
        )
        invalid_scanners = not isinstance(scanners, list) or not scanners
        if invalid_identifier or invalid_scanners:
            raise DispatchError(f"Invalid rule manifest: {directory}")
        identifiers.add(identifier)
        rules.append({"directory": directory, "manifest": manifest})
    return rules


def _validate_scanner(rule_id: str, directory: Path, scanner: object) -> None:
    if not isinstance(scanner, dict):
        raise DispatchError(f"Invalid scanner in rule: {rule_id}")
    extensions = scanner.get("extensions")
    runtime = scanner.get("runtime")
    entrypoint = scanner.get("entrypoint")
    invalid_extensions = (
        not isinstance(extensions, list)
        or not extensions
        or not all(
            isinstance(extension, str) and EXTENSION_PATTERN.fullmatch(extension)
            for extension in extensions
        )
    )
    invalid_runtime = runtime not in ("python3", "bun")
    invalid_entrypoint = not isinstance(entrypoint, str) or os.path.isabs(entrypoint)
    if invalid_extensions or invalid_runtime:
        raise DispatchError(f"Invalid scanner in rule: {rule_id}")
    if invalid_entrypoint:
        raise DispatchError(f"Invalid scanner in rule: {rule_id}")
    script = (directory / entrypoint).resolve()
    if not str(script).startswith(str(directory.resolve()) + os.sep):
        raise DispatchError(f"Invalid entrypoint in rule: {rule_id}")


def _language(entrypoint: str) -> str:
    return os.path.basename(os.path.dirname(entrypoint))


def _run_scanner(rule_id: str, directory: Path, scanner: dict, paths: list[str]) -> list:
    entrypoint = scanner["entrypoint"]
    runtime = scanner["runtime"]
    language = _language(entrypoint)
    script = str((directory / entrypoint).resolve())

    if runtime == "python3":
        environment = os.environ.copy()
        existing = environment.get("PYTHONPATH")
        environment["PYTHONPATH"] = (
            str(SKILL_ROOT) + (os.pathsep + existing if existing else "")
        )
        command = [sys.executable, script, *paths]
    else:
        bun = shutil.which("bun")
        if not bun:
            raise Skipped(rule_id, language, "bun not available on PATH")
        if not (SKILL_ROOT / "node_modules").is_dir():
            raise Skipped(
                rule_id,
                language,
                f"bun dependencies not installed; run `bun install` in {SKILL_ROOT}",
            )
        environment = os.environ.copy()
        command = [bun, script, *paths]

    result = subprocess.run(command, env=environment, capture_output=True, text=True)
    if result.returncode != 0:
        stderr = (result.stderr or "").strip()
        if RUFF_UNAVAILABLE in stderr:
            raise Skipped(
                rule_id,
                language,
                "ruff not available; run through `uv run --project` or install ruff",
            )
        if any(marker in stderr for marker in CHECKSTYLE_MARKERS):
            raise Skipped(rule_id, language, "java or checkstyle jar not available")
        raise DispatchError(f"Rule {rule_id} failed: {stderr or result.stdout.strip()}")
    try:
        output = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise DispatchError(f"Invalid findings from rule: {rule_id}: {error}")
    if not isinstance(output, list) or not all(
        _valid_finding(finding, rule_id, set(paths)) for finding in output
    ):
        raise DispatchError(f"Invalid finding from rule: {rule_id}")
    return output


def scan_rules(files: list[str], selected_rule: str | None = None) -> tuple[list, list]:
    rules = list_rules()
    if selected_rule and not any(
        rule["manifest"]["id"] == selected_rule for rule in rules
    ):
        raise DispatchError(f"Unknown rule: {selected_rule}")
    findings = []
    skips = []
    for rule in rules:
        rule_id = rule["manifest"]["id"]
        if selected_rule and rule_id != selected_rule:
            continue
        for scanner in rule["manifest"]["scanners"]:
            _validate_scanner(rule_id, rule["directory"], scanner)
            extensions = scanner["extensions"]
            targets = list(
                dict.fromkeys(
                    file
                    for file in files
                    if os.path.splitext(file)[1] in extensions
                )
            )
            if not targets:
                continue
            try:
                findings.extend(_run_scanner(rule_id, rule["directory"], scanner, targets))
            except Skipped as skip:
                skips.append(skip)
    return findings, skips
