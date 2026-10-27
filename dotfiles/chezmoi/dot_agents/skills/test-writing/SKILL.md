---
name: test-writing
description: >
  Test design techniques for black-box and white-box testing, plus rules for
  non-redundant tests and clean test code.
  Load whenever asked to add, tweak, or review tests in a codebase, or when
  asked whether something is tested well enough.
---

# Test Writing

The purpose of a test is to find flaws in the software.
Not to raise coverage, not to document, not to prove correctness.

A test that cannot fail for a reason you care about is dead weight — delete it.

Before writing a test, answer: **what defect does this test catch?**
If there is no answer, there is no test to write.

## Starting a session

Do not open with technique.
Open by establishing what the code is supposed to do.

1. Read the change and name the business goal it serves.
   A test suite that does not encode that goal is testing the wrong thing.
2. Extract the expected behaviour as hard rules — one line each, stated as an
   invariant the code must satisfy, in the language of the domain.
3. Write those rules as tests first, before any edge cases.
   They are the spec; if they pass on broken code, the rules are too loose.
4. Only then add adjacent tests — boundaries, error paths, illegal states —
   to catch the failures the spec lines alone would not.

Red before green: a new test must be observed failing for the intended reason.
A test that has never failed proves nothing about what it guards.
When the code already exists, get the same signal by breaking it deliberately.

Rules that cannot be stated as one line are not understood yet.
Go read the code or ask, do not paper over it with more assertions.

## Choosing a technique

| Information available | Use |
| --- | --- |
| Spec / contract only | Black-box techniques |
| Source visible | White-box to reach paths the spec does not name |
| Both | Black-box for the contract, white-box to find the gaps |

Write black-box tests first.
They survive refactoring; white-box tests are coupled to the current implementation.

Put each test at the lowest level that can detect the flaw.
A bug in a pure function does not need an end-to-end test.

## Black-box techniques

**Equivalence partitioning** — split the input domain into classes the code
should treat identically, test one value per class.
Two values from the same class are one test, not two.

**Boundary value analysis** — most defects live at edges.
For a range `[1, 100]`: test `0, 1, 2, 99, 100, 101`.
Also empty, single-element, exactly-at-limit, one-over-limit.

**Decision tables** — enumerate combinations of independent conditions and the
expected outcome, then drop rows that are impossible or provably equivalent.

**State transition testing** — for stateful units, test legal transitions and
attempted illegal ones (the illegal ones find more bugs).

**Pairwise / combinatorial** — with many independent parameters, full
cross-product is exponential and mostly redundant; cover all pairs instead.

**Negative and error-path testing** — null, empty, malformed, wrong type,
duplicate, out-of-order, oversized, unicode, injection-shaped input.
Assert the specific failure, not merely "it throws".

**Property-based testing** — assert invariants over generated input.
Strongest properties: round-trip (`decode(encode(x)) == x`), idempotence,
commutativity, order-independence, comparison against a slow reference
implementation, metamorphic relations (how the output must change when the
input changes).

**Fuzzing** — for parsers, deserializers, and anything reading untrusted bytes;
the oracle is "does not crash / does not corrupt state".

## White-box techniques

**Statement and branch coverage** — every line, every branch outcome.
Branch coverage is the floor, not the goal.

**Condition and MC-DC coverage** — for compound predicates, show that each
sub-condition independently changes the outcome.
A decision with `n` conditions needs `n + 1` tests, at most `2n`: one baseline
plus one flip per condition.
`if (a && b)` needs cases where `a` alone flips the result and where `b` does.
Two tests is decision coverage, not MC-DC.

**Loop testing** — zero iterations, one, many, and the boundary that terminates
or overflows.

**Path testing** — for small units with interacting branches; infeasible on
large ones, so scope it to the risky function.

**Data-flow (def-use) testing** — every variable definition exercised through
each use; finds stale state, uninitialized reads, invalidated caches.

**Exception and guard-clause coverage** — every early return and catch block.
Uncovered `catch` blocks are where wrong error handling hides.

**Concurrency** — interleavings, lock ordering, retry and idempotency paths.
Requires deterministic scheduling or stress with invariant checks; a test that
"usually passes" is worse than no test.

**Mutation testing** — the only direct measure of whether a suite finds flaws.
Change the code, see if a test fails.
Use it to judge the suite; use coverage only to find untested code.

Coverage is a diagnostic, never a target.
100% coverage with weak assertions catches nothing.

## Testing the contract, not just the logic

Every documented failure mode is a behaviour under test.
If a function throws, the throw is part of its API — a test must trigger it.

For each thrown exception, assert:

- That it is raised on the input that should raise it.
- The exact type, not a supertype and not `Exception`.
- The parts of the message, code, or payload that callers branch on.
- That state is unchanged when the call fails — no partial writes, no leaks.
- That the happy path does *not* raise it.

Same rule for error returns: `Result`/`Either`/error codes/`None` need the
failing variant asserted, with its content, not just "not ok".

Untested throws rot into the wrong type, a swallowed cause, or a guard someone
deleted without a single test failing.

```text
# counter-example — passes if it throws for any reason, including a typo in the test
def test_withdraw_fails():
    with pytest.raises(Exception):
        account.withdraw(999)

# example — pins type, message, and that the failure left no damage
def test_withdraw_over_balance_raises_insufficient_funds():
    account = Account(balance=100)
    with pytest.raises(InsufficientFunds, match="balance 100, requested 999"):
        account.withdraw(999)
    assert account.balance == 100
```

Wrapping and propagation are contract too: assert the cause survives when a
layer re-raises, and that internal exception types do not leak past a boundary
that promises its own error type.

## Eliminating redundancy

A new test must be able to fail for a reason no existing test can.
Apply that rule literally before adding one.

Then ask: if I delete this test, which bug escapes?
No answer means delete it.

Redundancy to remove:

- Tests differing only in input data → one parametrized/table-driven test.
- Tests covering the same equivalence class with different values.
- Tests that re-verify a dependency's behavior instead of your use of it.
- Tests asserting language, framework, or library behavior.
- Tests on generated code, trivial accessors, and pure delegation.
- An end-to-end test duplicating what a unit test already proves.
- Tests asserting implementation details — call order, private state, mock
  invocation counts — which fail on refactoring and pass on real breakage.

Also delete tests that cannot fail: no assertion, assertion on a mock's own
return value, or a tautology like `assertEquals(x, x)`.

## Clean test code

One reason to fail per test.
Multiple assertions are fine when they describe one behavior; two independent
behaviors are two tests.

```text
# counter-example — one failure hides the rest, name says nothing
def test_user():
    assert create("bob").name == "bob"
    assert create("").is_err()
    assert create("bob" * 100).is_err()

# example — independent failures, names localize the fault
def test_create_preserves_name(): ...
def test_create_rejects_empty_name(): ...
def test_create_rejects_name_over_max_length(): ...
```

Name tests `<unit>_<scenario>_<expected outcome>`.
The name must be readable as the spec line it enforces.

Keep the arrange / act / assert split visible, with exactly one act.

No logic in tests — no conditionals, loops, or `try` used for control flow.
Logic in a test is untested code guarding tested code.

```text
# counter-example — branch means one path is silently never asserted
def test_discount():
    result = discount(user)
    if user.is_premium:
        assert result == 0.2
    else:
        assert result == 0.0

# example — the table is the spec
@parametrize("premium,expected", [(True, 0.2), (False, 0.0)])
def test_discount(premium, expected):
    assert discount(User(premium=premium)) == expected
```

Prefer explicit local setup over shared mutable fixtures; use builders with
defaults so each test names only the fields it cares about.

DAMP over DRY: duplication that keeps a test readable in isolation is cheaper
than an abstraction that hides what is being tested.
Extract setup noise, never the assertion.

Tests must be deterministic and order-independent: inject the clock, seed the
randomness, no real network, no `sleep`, no state leaking between tests.

## Test doubles

Mock at boundaries you own the contract for — I/O, network, clock, external
services.
Never mock the unit under test or the types it operates on.

Prefer a fake (in-memory implementation) for stateful dependencies over a stack
of stubs; prefer real objects over fakes when they are cheap.

Over-mocking produces a suite that passes while the system is broken.
If a test only asserts that mocks were called, it tests the mock wiring.

## Reviewing existing tests

1. Break the production code deliberately — anything from a flipped comparison
   to a removed guard clause. Nothing fails → the suite does not test that.
2. Look for tests with no assertion, or assertions only on mocks.
3. Find groups of tests that die together on one change; collapse them.
4. Check the error and boundary paths — usually the actual gap.
5. Check determinism: clock, randomness, network, ordering, shared state.
6. Report the missing defect classes, not the coverage percentage.

Removing weak tests is as valuable as adding strong ones.
State plainly which tests you deleted and which defect each one failed to catch.

## References

[Adequacy Criteria](references/adequacy-criteria.md) — per technique: the source,
the count or set that says when the technique is satisfied, and one example.
Read it when you need to justify that a technique was applied, or argue that it
was not.
