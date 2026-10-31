import json
import subprocess
from pathlib import Path

from viqui.core.finding import Finding

RUFF = Path(__file__).resolve().parents[2] / ".venv" / "bin" / "ruff"


def scan_ruff(
    paths: list[str], *, config: Path, codes: set[str], rule: str, message: str
) -> list[Finding]:
    result = subprocess.run(
        [
            str(RUFF),
            "check",
            "--config",
            str(config),
            "--no-fix",
            "--ignore-noqa",
            "--no-cache",
            "--output-format",
            "json",
            *paths,
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode not in (0, 1):
        raise RuntimeError(f"Ruff failed: {result.stderr}")
    diagnostics = json.loads(result.stdout)
    if any(item["code"] not in codes for item in diagnostics):
        raise ValueError(f"Ruff returned unexpected diagnostics: {diagnostics}")
    return list(
        dict.fromkeys(
            Finding(
                rule=rule,
                file=item["filename"],
                line=item["location"]["row"],
                column=item["location"]["column"],
                message=message,
            )
            for item in diagnostics
        )
    )
