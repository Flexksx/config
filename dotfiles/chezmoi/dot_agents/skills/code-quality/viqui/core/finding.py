import json
import sys
from collections.abc import Iterable
from dataclasses import asdict, dataclass


@dataclass(frozen=True, kw_only=True)
class Finding:
    rule: str
    file: str
    line: int
    column: int
    message: str


def write_findings(findings: Iterable[Finding]) -> None:
    sys.stdout.write(json.dumps([asdict(finding) for finding in findings]))
