# Python Project Bootstrap

## Init

```bash
uv init my-project
cd my-project
uv add --dev ruff ty pytest
```

## Structure

```text
my-project/
├── pyproject.toml
├── src/
│   └── my_project/
│       ├── __init__.py
│       └── ...
└── tests/
    └── test_*.py
```

Always use `src/` layout to avoid import conflicts between installed package and local source.

## `pyproject.toml` Baseline

```toml
[tool.ruff]
line-length = 100
target-version = "py314"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM"]

[tool.pytest.ini_options]
testpaths = ["tests"]
```
