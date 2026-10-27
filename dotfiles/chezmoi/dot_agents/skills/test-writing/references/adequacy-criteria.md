# Adequacy Criteria

One entry per technique.
Each entry gives the source, the condition that says when the technique is
satisfied, why that condition works, and the smallest example that shows it.

The condition is the stopping rule.
If you cannot state it as a count or a set, you cannot claim the technique was
applied.

Quotes marked `~` are close paraphrase, not verbatim.
Check the source before you reuse them as quotes.

## Equivalence partitioning

> ~ "A well-selected test case reduces, by more than a count of one, the number
> of other test cases that must be developed."
> Myers, *The Art of Software Testing*, ch. 4.

**Condition.**
Split the input domain `D` into classes `C₁..Cₙ` that are disjoint and whose
union is `D`.
Test exactly one value per class, valid classes and invalid classes both.
Test count equals the class count.

**Why.**
The uniformity hypothesis (Bernot, Gaudel & Marre, 1991): if the program is
correct for one member of a class, it is correct for every member.
A second value from the same class can only fail for the same reason, so it adds
nothing.
If two values from one class can fail differently, the partition is wrong, not
the test.

```python
# spec: shipping(weight_kg) -> 5 if weight <= 2, 12 if 2 < weight <= 10, reject above 10
# classes: [0, 2], (2, 10], (10, inf), negative, non-numeric

# counter-example: 1.0 and 1.5 sit in the same class, so this is one test written twice
shipping(1.0) == 5
shipping(1.5) == 5

# example: one value per class, invalid classes included
shipping(1.0) == 5
shipping(6.0) == 12
raises(TooHeavy): shipping(11.0)
raises(BadWeight): shipping(-1.0)
```

## Boundary value analysis

> "Bugs lurk in corners and congregate at boundaries."
> Beizer, *Software Testing Techniques*, 2nd ed., ch. 6.

**Condition.**
For every border at `c`, the suite must contain the pair `c - δ` and `c`, where
`δ` is the least step of the type: 1 for integers, 1 ulp for floats, one element
for collections.
The two values must expect different results.

**Why.**
No test point between them means a border placed anywhere in the gap classifies
every test the same way as the correct border.
A gap of `δ` leaves nowhere for a misplaced border to hide.
This catches a wrong constant and a wrong operator, `>` against `>=`.

```python
# spec: is_adult(age) == (age >= 18)

# counter-example: gap of 20, so any border in (10, 30] passes
is_adult(10) is False
is_adult(30) is True

# example: gap of 1, so >18, >=17 and >=19 all fail
is_adult(17) is False
is_adult(18) is True
```

**Note on the classic six-value list.**
For a range `[1, 100]`, `0, 1, 100, 101` satisfies the condition above.
The extra `2` and `99` come from Jorgensen's `4n+1` scheme and target a different
fault, bad arithmetic near the edge, not a misplaced border.
Add them when that fault is plausible, and say so.

## Decision tables

> ~ "Decision tables are ideal for describing situations in which a number of
> combinations of actions are taken under varying sets of conditions."
> Copeland, *A Practitioner's Guide to Software Test Design*, ch. 5.

**Condition.**
With `n` binary conditions the table has `2^n` rules.
The table is adequate when every one of the `2^n` combinations maps to exactly
one row, and every feasible row has a test.
Collapse rows only where a condition provably cannot change the action.

**Why.**
Completeness catches the missing case, the combination nobody thought about.
Consistency catches the contradiction, two rows with the same conditions and
different actions.
Both checks are arithmetic on the table, so they need no insight.

```text
# spec: free_shipping(is_member, over_100)
# 2 conditions, so 4 rules, all four feasible

member | over_100 | free
   T   |    T     |  yes
   T   |    F     |  yes
   F   |    T     |  yes
   F   |    F     |  no

# counter-example: 3 rows for 2 conditions. The missing row is where the bug lives.
# example: 4 rows, sum of covered combinations equals 2^2
```

## State transition testing

> ~ "The finite-state machine is as fundamental to software engineering as
> boolean algebra is to hardware."
> Beizer, *Software Testing Techniques*, ch. 11.

**Condition.**
Two counts, both required.
Legal: one test per defined transition, so `|T|` tests, called 0-switch coverage
(Chow, 1978).
Illegal: one test per `(state, event)` pair that has no defined transition, so
`|S| × |E| - |T|` tests, called sneak paths (Binder).

**Why.**
Transition coverage proves each legal move works once.
Sneak paths find more bugs, because code that guards legal moves is written on
purpose and code that rejects illegal moves is usually forgotten.

```python
# spec: order states {new, paid, shipped, cancelled}, events {pay, ship, cancel}
# defined transitions: 4. Grid is 4 x 3 = 12. Sneak paths: 8.

# example: legal transition
order(state="paid").ship().state == "shipped"

# example: sneak path, the one that finds the double-charge bug
raises(IllegalTransition): order(state="shipped").pay()
```

## Pairwise and combinatorial

> ~ "The majority of faults involved a single parameter, and most of the
> remainder involved two parameters interacting."
> Kuhn, Wallace & Gallo, *Software Fault Interactions and Implications for
> Software Testing*, IEEE TSE, 2004.

**Condition.**
For every pair of parameters, every combination of their values appears in at
least one test.
That is 2-way coverage.
Raise the strength to 3-way or higher only for a component where the NIST data
does not hold, for example a security decision built from four flags.

**Why.**
Full cross product is `v^k` and grows exponentially.
Pairwise grows as `v²·log k`.
Since 70 to 95 percent of faults are triggered by one or two parameters, the
extra tests in the cross product mostly re-test the same interaction.

```text
# 4 parameters, 3 values each

# counter-example: full cross product, 81 tests, and 72 of them add no new pair
# example: a covering array of 9 tests holds every pair of every parameter pair
```

## Negative and error-path testing

> "Test cases must be written for invalid and unexpected, as well as valid and
> expected, input conditions."
> Myers, *The Art of Software Testing*, ch. 2.

**Condition.**
For every failure mode named in the contract there is one test that triggers it
and asserts four things: the exact error type, the part of the message or code
that callers branch on, that state did not change, and that the happy path does
not raise it.
Ratio of tested failure modes to documented failure modes must be 1.

**Why.**
A thrown error is a return value with a different shape.
An untested error path rots into the wrong type, a swallowed cause, or a partial
write, and no test notices.

```python
# counter-example: passes if it throws for any reason, including a typo in the test
with raises(Exception):
    account.withdraw(999)

# example: pins type, payload, and that the failure left no damage
account = Account(balance=100)
with raises(InsufficientFunds, match="balance 100, requested 999"):
    account.withdraw(999)
assert account.balance == 100
```

## Property-based testing

> ~ "The programmer writes specifications as properties, and the tool tests that
> they hold for a large number of randomly generated cases."
> Claessen & Hughes, *QuickCheck: A Lightweight Tool for Random Testing of
> Haskell Programs*, 2000.

**Condition.**
A property is a claim `∀x ∈ D. P(x)` where `P` is computable without knowing the
expected output.
The property is strong enough only if a wrong implementation exists that
violates it.
Fast check: if `return input` or `return constant` satisfies the property, the
property is too weak.

**Why.**
The value of a property is the set of wrong programs it rejects.
A property that a stub passes rejects nothing, so it cannot fail for a reason
you care about.

```python
# counter-example: the identity function passes this, so it proves nothing about sorting
len(my_sort(xs)) == len(xs)

# example: only a correct sort passes both
is_ascending(my_sort(xs))
multiset(my_sort(xs)) == multiset(xs)
```

Strongest shapes, in order: round trip `decode(encode(x)) == x`, comparison
against a slow reference implementation, metamorphic relations, idempotence,
commutativity.

## Fuzzing

> ~ "We were able to crash more than 24 percent of the utility programs we
> tested."
> Miller et al., *An Empirical Study of the Reliability of UNIX Utilities*, 1990.

**Condition.**
Three requirements.
The oracle is a total invariant, checkable on any input without knowing the
expected output: no crash, no memory error, no hang, no corrupt state.
The fuzzer is coverage guided, otherwise it re-tests the same shallow path
forever.
Every crash is reduced to a minimal input and committed as a normal regression
test.

**Why.**
Fuzzing has no expected output, so the invariant is the whole test.
Without coverage feedback, random bytes almost never reach past the first parse
check, so the deep code is untested.

```python
# example oracle set for a parser
parse(random_bytes)              # must not panic, must not hang
parse(serialize(x)) == x         # round trip on anything that parses
```

## Statement and branch coverage

> "Program testing can be used to show the presence of bugs, but never to show
> their absence."
> Dijkstra, *Notes on Structured Programming*, 1970.

**Condition.**
Statement coverage: every reachable statement executes once.
Branch coverage: every decision takes both outcomes at least once, so 2 tests
per decision minimum.
Branch coverage subsumes statement coverage.
The reverse is false.

**Why.**
A statement can execute with only one outcome of the branch that guards it.
The untaken outcome is where the missing else lives.

```python
# counter-example: one test with x=2 gives 100% statement coverage
def reciprocal(x):
    if x != 0:
        return 1 / x
    # the missing return is invisible to statement coverage

# example: branch coverage forces the second test, which returns None and exposes the gap
reciprocal(2) == 0.5
reciprocal(0)   # what should this be? Branch coverage makes you answer.
```

## Condition and MC-DC coverage

> Chilenski & Miller, *Applicability of Modified Condition/Decision Coverage to
> Software Testing*, Software Engineering Journal, 1994.
> The `n+1` bound is their result.
> DO-178C makes MC-DC mandatory for avionics software.

**Condition.**
For a decision with `n` atomic conditions, MC-DC needs `n + 1` tests, at most
`2n`.
Each condition must be shown to flip the decision on its own, with every other
condition held fixed.

| Criterion | Tests per decision |
| --- | --- |
| Decision coverage | 2 |
| Condition coverage | 2 |
| MC-DC | n+1 to 2n |
| Multiple condition | 2^n |

**Why.**
`n+1` sits between 2, which cannot tell which condition mattered, and `2^n`,
which is unaffordable past four conditions.
One baseline plus one flip per condition is the smallest set that assigns blame
to a single condition.

```python
# if (a and b and c): 3 conditions, so 4 tests, not 8

(T, T, T) -> True     # baseline
(F, T, T) -> False    # a alone flips the outcome
(T, F, T) -> False    # b alone flips
(T, T, F) -> False    # c alone flips

# counter-example: (T,T,T) and (F,F,F) is decision coverage, not MC-DC.
# A dropped `and c` still passes both.
```

Cyclomatic complexity `V(G) = decisions + 1` is a different number.
It counts independent paths through a whole function, not conditions in one
decision.

## Loop testing

> Beizer, *Software Testing Techniques*, ch. 3, prescribes: bypass the loop, one
> pass, two passes, typical, `max - 1`, `max`, `max + 1`.

**Condition.**
Test iteration counts `0, 1, 2, N-1, N, N+1` where `N` is the bound.
Loop testing is boundary value analysis applied to the iteration counter.

**Why.**
Zero catches a loop that always runs once, the `do while` written as `while`.
One catches bad initialisation.
Two is the first count where state carries from one pass to the next, so it is
the only one that tests the carry.
`N` and `N+1` are the border pair from boundary value analysis.

```python
# counter-example: a 5-element test passes even though the total resets every pass
def total(xs):
    for x in xs:
        acc = 0      # bug: reset inside the loop
        acc += x
    return acc
# total([1,2,3,4,5]) == 5, and 5 looks plausible

# example: 2 elements is the smallest count that exposes it
total([]) == 0
total([7]) == 7
total([3, 4]) == 7   # returns 4, fails here
```

## Path testing

> McCabe, *A Complexity Measure*, IEEE TSE, 1976.

**Condition.**
Basis path coverage needs `V(G)` tests, where `V(G) = E - N + 2` on the control
flow graph, which equals `decisions + 1` for a single entry and single exit.
Every path through the function is a combination of the basis paths.
Complete path coverage is not a condition you can meet, because one loop makes
the path count unbounded.

**Why.**
`V(G)` is a basis, not the whole space, so it is the largest path criterion that
stays finite.
Scope it to one risky function with interacting branches.
Do not attempt it on a whole module.

```python
# two sequential ifs
# V(G) = 3, so basis path coverage is 3 tests
# complete path coverage is 2 x 2 = 4
# the fourth path is where a shared variable set by both ifs collides
```

## Data-flow testing

> Rapps & Weyuker, *Selecting Software Test Data Using Data Flow Information*,
> IEEE TSE, 1985.

**Condition.**
All-uses coverage: for every definition `d` of a variable and every use `u` that
`d` can reach without another write in between, run at least one path from `d` to
`u`.
Count equals the number of such def-use pairs.

**Why.**
Branch coverage asks whether a line ran.
Data-flow asks whether a value survived from where it was written to where it was
read.
That is the question behind stale caches, uninitialised reads, and state left
over between calls.

```python
# 3 definitions of cache, 1 use. The pair that matters is invalidate -> read.

# counter-example: covers set -> read, which always works
cache.set("k", 1); cache.get("k") == 1

# example: covers invalidate -> read, where the stale value shows up
cache.set("k", 1); cache.invalidate("k"); cache.get("k") is None
```

## Exception and guard-clause coverage

> ~ "A routine call must either succeed and fulfil its contract, or fail and
> report failure."
> Meyer, *Object-Oriented Software Construction*, on Design by Contract.

**Condition.**
Every `raise` site, every `catch` block, and every early return is entered by at
least one test.
Entered is not enough on its own: each one must also assert the error identity
and that state is unchanged.

**Why.**
A `catch` block that no test enters is code that has never run.
Wrong error handling hides there, and coverage tools report the file as covered
because the happy path went through it.

```python
# counter-example: the retry path is never entered, so the bug in it is invisible
try:
    return fetch(url)
except Timeout:
    return fetch(url, retries=0)   # bug: no retry at all

# example: force the exception, then assert the specific outcome
with fake_network(fails_with=Timeout):
    assert fetch_with_retry(url).attempts == 2
```

## Concurrency

> Jim Gray, *Why Do Computers Stop and What Can Be Done About It?*, 1985, names
> the Heisenbug: the fault that disappears when you look at it.

**Condition.**
The failing interleaving must be reached with probability 1.
That means a controlled schedule: a deterministic scheduler, injected barriers,
or systematic exploration of interleavings.
For a concurrent data structure, the oracle is linearizability, that some serial
order explains the observed results.

**Why.**
If the schedule is left to the operating system, the pass or fail result is not a
function of the code.
A test that usually passes carries no information, and it trains the team to
re-run the suite instead of reading the failure.

```python
# counter-example: passes by luck most runs, so a lost update never gets reported
run_threads(2, lambda: counter.increment())
assert counter.value == 2

# example: the barrier forces the interleaving that loses the update, every run
with barrier_after(counter, "read"):
    run_threads(2, lambda: counter.increment())
assert counter.value == 2   # fails deterministically until the increment is atomic
```

## Mutation testing

> "Test data that distinguishes all programs differing from a correct one by only
> simple errors is so sensitive that it also implicitly distinguishes more
> complex errors."
> DeMillo, Lipton & Sayward, *Hints on Test Data Selection*, 1978.
> That is the coupling effect.
> Their second assumption is the competent programmer hypothesis: real programs
> are close to correct, so simple mutants model real bugs.

**Condition.**
Mutation score equals killed mutants divided by total mutants minus equivalent
mutants.
Target is 1.
Equivalent mutants are semantically identical to the original, so no test can
kill them, and detecting them is undecidable.
That is why the practical target sits below 1 and why every surviving mutant must
be read, not just counted.

**Why.**
Mutation testing is the only measure that answers the question the suite exists
for: does a test fail when the code is wrong.
Coverage answers a weaker question: did the line run.

```python
# example loop that turns a survivor into a test
# 1. mutate: is_adult uses `>` instead of `>=`
# 2. run the suite. Nothing fails, so the mutant survives.
# 3. the surviving mutant names the missing test: the boundary pair at 18
is_adult(17) is False
is_adult(18) is True
# 4. re-run the mutant. It dies. The suite got stronger, not just greener.
```

Use mutation testing to judge the suite.
Use coverage only to find code no test touches.
