# Thin abstractions

A thin abstraction forwards work it adds nothing to.
It is a wrapper that only delegates, a class that holds no state, or a
boolean parameter that switches behavior.

These shapes are cheap to write and expensive to maintain.
Each one is a name a reader must resolve before they can see what the code
does.

The cost compounds.
A wrapper around a wrapper is two names for one operation.
A stateless class hides a group of functions behind an object that has no
reason to exist.
A boolean parameter turns one operation into two behaviors that share a
signature.

## Why the rules exist

The rules report these shapes so you can remove them before they become
load-bearing.
Removing a thin abstraction early is one edit.
Removing it after other code routes through it is a migration.

The rules are structural, not stylistic.
They do not report taste or naming.
They report indirection that has no observable effect.

## What a finding means

A finding names the shape and the line.
It does not fix the code.
Decide whether the shape earns its indirection, then act.

If it earns it, the right move is usually a comment or a rename that makes
the reason visible.
If it does not, the right move is to delete it and call the underlying code
directly.
