from pathlib import Path

import pytest
from scan import scan

FIXTURES = Path(__file__).parent / "fixtures"


def test_scan_reports_direct_call_with_presets() -> None:
    findings = scan(FIXTURES / "direct_call.py")

    assert [(finding.line, finding.column) for finding in findings] == [(2, 5)]


@pytest.mark.parametrize(
    "filename",
    [
        "callback.py",
        "module_function.py",
        "decorated_function.py",
        "same_name_different_scope.py",
        "transformed_argument.py",
    ],
)
def test_scan_skips_nontrivial_or_ambiguous_wrappers(filename: str) -> None:
    findings = scan(FIXTURES / filename)

    assert findings == []


def test_scan_rejects_invalid_syntax() -> None:
    with pytest.raises(SyntaxError):
        scan(FIXTURES / "invalid_syntax.txt")
