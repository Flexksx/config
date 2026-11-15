import json
import os
import subprocess
import sys
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[2]
CLI = SKILL_ROOT / "viqui" / "cli.py"
RULES = SKILL_ROOT / "viqui" / "rules"

if str(SKILL_ROOT) not in sys.path:
    sys.path.insert(0, str(SKILL_ROOT))

STDLIB_RULES = [
    "no-comments",
    "no-long-boolean-chain",
    "no-nested-ternary",
    "no-stateless-class",
    "no-thin-wrapper",
]

RUFF_RULES = [
    "no-boolean-parameter",
    "no-complex-if-condition",
    "no-deep-nesting",
    "no-empty-exception-handler",
]


def run_cli(*args, env=None):
    environment = os.environ.copy()
    if env:
        environment.update(env)
    return subprocess.run(
        [sys.executable, str(CLI), *args],
        capture_output=True,
        text=True,
        env=environment,
    )


def check(rule, *args, env=None):
    return run_cli("check", "--rule", rule, *args, env=env)


def fixture(rule, name):
    return str(RULES / rule / "py" / "test" / "fixtures" / f"{name}.py")


def stdout_json(result):
    return json.loads(result.stdout)
