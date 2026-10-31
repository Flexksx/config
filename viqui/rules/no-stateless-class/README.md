# Stateless classes

This rule reports classes that group methods without visible instance state, such as a stateless service or repository.
Consider replacing the class with module functions when its type is not needed as an interface or framework boundary.
Findings are review prompts, not automatic fixes.

The Python scanner skips classes with bases, decorators, class assignments, decorated or special methods, and instance access other than calls to methods on the same class.
The TypeScript scanner reports instance members that do not use `this` and classes containing only static members.
It can report members of inherited classes and interface implementations.
Both scanners work within a single file and cannot determine whether external callers require a class.
Vue files and Svelte files are not scanned.
