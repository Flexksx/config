# Python Testing Standards

## File Layout

One test file per module: `tests/test_<module>.py`.

## Naming

`test_<function>_<scenario>`:

```python
def test_process_returns_empty_on_no_input():
    assert process([]) == {}
```

## Fixtures

Use `pytest.fixture` for shared setup. Avoid `setUp`/`tearDown` style.

## Parametrize

```python
@pytest.mark.parametrize("value,expected", [
    (0, False),
    (1, True),
    (-1, False),
])
def test_is_positive(value, expected):
    assert is_positive(value) == expected
```

## Mocking

Mock at the boundary (I/O, network, DB) — not deep inside logic. Prefer `pytest-mock` (`mocker` fixture).
