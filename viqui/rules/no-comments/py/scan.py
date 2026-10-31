import io
import re
import sys
import tokenize
from pathlib import Path

from viqui.core.finding import Finding, write_findings

RULE_ID = "no-comments"
MESSAGE = "Comment found; consider expressing the intent in code."
DIRECTIVE = re.compile(
    r"^#\s*(?:noqa\b|type:\s*ignore\b|pyright:|mypy:|ruff:|fmt:|isort:|coverage:|pragma:|coding[:=])"
)


def scan(path: Path) -> list[Finding]:
    source = path.read_text(encoding="utf-8")
    findings = []
    for token in tokenize.generate_tokens(io.StringIO(source).readline):
        if token.type != tokenize.COMMENT:
            continue
        is_shebang = token.start[0] == 1 and token.string.startswith("#!")
        if is_shebang or DIRECTIVE.match(token.string):
            continue
        findings.append(
            Finding(
                rule=RULE_ID,
                file=str(path),
                line=token.start[0],
                column=token.start[1] + 1,
                message=MESSAGE,
            )
        )
    return findings


if __name__ == "__main__":
    write_findings(finding for path in sys.argv[1:] for finding in scan(Path(path)))
