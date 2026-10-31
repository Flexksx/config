import sys
from pathlib import Path

from viqui.core.finding import write_findings
from viqui.shared.ruff import scan_ruff

RULE_ID = "no-complex-if-condition"
MESSAGE = "This if condition has more than two boolean expressions; consider extracting a named condition."

if __name__ == "__main__":
    write_findings(
        scan_ruff(
            sys.argv[1:],
            config=Path(__file__).with_name("ruff-config.toml"),
            codes={"PLR0916"},
            rule=RULE_ID,
            message=MESSAGE,
        )
    )
