import json

import pytest

from conftest import STDLIB_RULES, fixture, run_cli, stdout_json


def test_list_prints_all_rule_ids():
    result = run_cli("list")
    assert result.returncode == 0
    assert len(stdout_json(result)) == 9


def test_check_reports_one_rule():
    result = run_cli("check", "--rule", "no-comments", fixture("no-comments", "invalid"))
    assert result.returncode == 0
    findings = stdout_json(result)
    assert len(findings) == 1
    assert findings[0]["rule"] == "no-comments"
    assert findings[0]["file"].endswith("invalid.py")


def test_valid_fixture_has_no_findings():
    result = run_cli("check", "--rule", "no-comments", fixture("no-comments", "valid"))
    assert result.returncode == 0
    assert stdout_json(result) == []


def test_unknown_rule_exits_two():
    result = run_cli("check", "--rule", "nope", fixture("no-comments", "invalid"))
    assert result.returncode == 2
    assert "Unknown rule" in result.stderr


def test_fail_on_findings_exits_one():
    result = run_cli(
        "check", "--fail-on-findings", "--rule", "no-comments",
        fixture("no-comments", "invalid"),
    )
    assert result.returncode == 1


def test_findings_match_the_schema():
    result = run_cli("check", "--rule", "no-thin-wrapper", fixture("no-thin-wrapper", "invalid"))
    assert result.returncode == 0
    for finding in stdout_json(result):
        assert finding["rule"]
        assert finding["file"]
        assert isinstance(finding["line"], int) and finding["line"] >= 1
        assert isinstance(finding["column"], int) and finding["column"] >= 1
        assert finding["message"]


@pytest.mark.parametrize("rule", STDLIB_RULES)
def test_stdlib_rules_flag_invalid_and_pass_valid(rule):
    invalid = run_cli("check", "--rule", rule, fixture(rule, "invalid"))
    assert invalid.returncode == 0
    assert stdout_json(invalid), f"{rule} did not flag its invalid fixture"
    valid = run_cli("check", "--rule", rule, fixture(rule, "valid"))
    assert valid.returncode == 0
    assert stdout_json(valid) == [], f"{rule} flagged its valid fixture"
