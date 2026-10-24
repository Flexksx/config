---
name: python-dev
description: >
  Always load when developing, writing, reviewing, or refactoring Python code.
  Python development best practices, tooling, project structure, and code quality standards.
---

# Python Development

Also load the `software-engineering` skill for general coding principles.

## Tooling Defaults

| Concern | Tool |
|---------|------|
| Package manager | `uv` (not pip/poetry) |
| Linter/formatter | `ruff` |
| Type checker | `ty` |
| Testing | `pytest` |
| Env isolation | `uv venv` or `uv run` |

## Core Principles

## Explicitness Over Implicit Behavior

Everything must be explicit.
No hidden control flow, magic values, or global dependencies.
Dependencies are passed as arguments; data flow is visible at the call site.

## Pythonic Design

Python is module-centric, not class-centric.
Every module is already a singleton — use files as namespaces rather than wrapping stateless logic in classes.
Use classes only when you need per-instance state (different instances are meaningfully different).

## Self-Documenting Code

Code is self-explanatory through naming, types, and structure.
Comments are not allowed — if something needs a comment, rewrite it until it doesn't.
The only exceptions are module-level docstrings and pragmas (`# noqa`, `# type: ignore`) with inline explanations.

## Code Quality Rules

### Module Design

```python
# Non-pythonic: BrandService class wraps stateless methods
from brands.service import BrandService
brand_service: BrandService = BrandService()
brand: Brand = brand_service.get("abc")

# Pythonic: module is the namespace, functions are the API
# brands/service.py
import brand.repository as brand_repository

async def get(id: str, db: DatabaseConnection) -> Brand:
    return await brand_repository.find_by_id(id, db)

# Usage
import brand.service as brand_service
brand: Brand = await brand_service.get("abc", db)
```

## When to use classes

Use a class only when two instances of the same type are meaningfully different due to per-instance configuration.
If you cannot construct two meaningfully different instances, use a module instead.

```python
# Justified: each instance has distinct config that changes behavior
gemini = LLMClient(api_key="...", provider="google")
openai = LLMClient(api_key="...", provider="openai")

github = APIClient(base_url="https://api.github.com", token="...")
gitlab = APIClient(base_url="https://gitlab.com/api/v4", token="...")

primary_db = ConnectionPool(host="primary", max_connections=20)
replica_db = ConnectionPool(host="replica", max_connections=5)
```

### Type Hints

Mandatory on all function signatures:

```python
def process(items: list[str], limit: int = 10) -> dict[str, int]:
    ...
```

and variables:

```python
multiplier: int = 10
item_names: list[str] = []
```

### Exception Handling

Catch specific, named exceptions; never catch bare `except` or swallow silently.
Log with context before re-raising; raise domain-specific exceptions that extend `Exception`.

```python
try:
    result = fetch_data(url)
except ConnectionError as e:
    logger.error("Failed to connect to %s: %s", url, e)
    raise
except TimeoutError as e:
    logger.error("Request timeout for %s: %s", url, e)
    raise
```

### Structured Data

Use dataclasses or Pydantic models instead of plain dicts.
Use Pydantic when validation or serialization is needed (API payloads, config files).

```python
from dataclasses import dataclass

@dataclass(frozen=True, kw_only=True)
class Config:
    host: str
    port: int = 8080
```

You may use plain dicts or lists as means for algorithm implementation,
like for a hashmap or some index, where a cheap primitive lookup offers more than an abstraction.

### Anti-Patterns to Avoid

**Imports**: Use explicit imports, never `import *`.

**Global Mutable State**: Pass dependencies as arguments instead of accessing global state.

**String Formatting**: Use f-strings, not `%` or `.format()`.

```python
# Good
message: str = f"User {name} logged in at {timestamp}"
# Bad
message: str = "User %s logged in at %s" % (name, timestamp)
```

**Observability**: Use the `logging` module, not `print()`.

**Mutable Default Arguments**:
Defaults are evaluated once at function definition.
Use `None` and construct inside.

```python
def add(item: str, items: list[str] | None = None) -> list[str]:
    if items is None:
        items = []
    items.append(item)
    return items
```

**Filesystem**:
Use `pathlib.Path` instead of `os.path` for all operations.

**Comprehensions**:
Use comprehensions when transforming collections.

```python
# Good: declarative, intent is clear
result: list[int] = [x * 2 for x in items if x > 0]

# Bad: imperative, more steps
result: list[int] = []
for x in items:
    if x > 0:
        result.append(x * 2)
```

**Iteration**:
Use `enumerate` and `zip` instead of index arithmetic.

```python
for idx, item in enumerate(items):     # better than range(len(items))
for name, score in zip(names, scores): # better than manual indexing
```

**Resources**:
Use `with` for any resource needing cleanup — files, DB connections, locks.
Ensures cleanup even if an exception occurs.

**Caching**:
Use `functools.lru_cache` or `functools.cache` for pure functions called repeatedly with the same arguments.

### Async Code

Use `asyncio` + `async/await`.
For FastAPI: inject dependencies via `Depends`, use `async def` for I/O-bound route handlers.

## References

[Project Bootstrap](references/python-project-bootstrap.md) — init, structure, `pyproject.toml` (new projects)

[Testing Standards](references/python-testing.md) — naming, fixtures, parametrize, mocking (when writing tests)
