import os
import tempfile

import pytest

from conftest import RULES, SKILL_ROOT, fixture, run_cli, stdout_json


@pytest.fixture()
def empty_path():
    directory = tempfile.mkdtemp()
    yield {"PATH": directory}
    os.rmdir(directory)


def test_missing_bun_reports_skip_on_stderr(empty_path):
    result = run_cli(
        "check",
        "--rule",
        "no-comments",
        str(RULES / "no-comments" / "ts" / "test" / "fixtures" / "invalid.ts"),
        env=empty_path,
    )
    assert result.returncode == 0
    assert stdout_json(result) == []
    assert "bun not available" in result.stderr


@pytest.mark.skipif(
    (SKILL_ROOT / ".venv" / "bin" / "ruff").is_file(),
    reason="skill .venv would provide ruff",
)
def test_missing_ruff_reports_skip_on_stderr(empty_path):
    result = run_cli(
        "check",
        "--rule",
        "no-boolean-parameter",
        fixture("no-boolean-parameter", "invalid"),
        env=empty_path,
    )
    assert result.returncode == 0
    assert stdout_json(result) == []
    assert "ruff not available" in result.stderr
