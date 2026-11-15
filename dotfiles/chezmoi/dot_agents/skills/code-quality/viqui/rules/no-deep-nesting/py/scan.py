import sys
from pathlib import Path

from viqui.core.finding import write_findings
from viqui.shared.ruff import scan_ruff

RULE_ID = "no-deep-nesting"
MESSAGE = "More than three nested blocks; consider extracting a function or using guard clauses."

if __name__ == "__main__":
    write_findings(
        scan_ruff(
            sys.argv[1:],
            config=Path(__file__).with_name("ruff-config.toml"),
            codes={"PLR1702"},
            rule=RULE_ID,
            message=MESSAGE,
        )
    )
