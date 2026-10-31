import sys
from pathlib import Path

from viqui.core.finding import write_findings
from viqui.shared.ruff import scan_ruff

RULE_ID = "no-boolean-parameter"
MESSAGE = (
    "Boolean positional parameter switches behavior; consider separate operations."
)

if __name__ == "__main__":
    write_findings(
        scan_ruff(
            sys.argv[1:],
            config=Path(__file__).with_name("ruff-config.toml"),
            codes={"FBT001", "FBT002"},
            rule=RULE_ID,
            message=MESSAGE,
        )
    )
