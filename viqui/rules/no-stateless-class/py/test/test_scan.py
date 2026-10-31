from pathlib import Path

from scan import scan


def test_scan_reports_stateless_service_but_not_configured_repository(tmp_path: Path) -> None:
    source = tmp_path / "layers.py"
    source.write_text(
        "class Service:\n"
        "    def get(self, key):\n"
        "        return repository.get(key)\n"
        "\n"
        "class Repository:\n"
        "    def get(self, key):\n"
        "        return self.database.get(key)\n"
    )

    findings = scan(source)

    assert [(finding.line, finding.column) for finding in findings] == [(1, 1)]
