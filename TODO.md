Things that I personally may want to implement.
But maybe i'll do this in the more optimised c version.

- [ ] Add more passes to our resolver [1]
- [ ] `continue` keyword support for loops. Maybe we'll not want to add for as a sync sugar, but as a manual implementation.
- [ ] The `print` shouldn't be a built-in keyword, but a foreign function.
- [ ] (BIG COMMITMENT) Support for *foreign functions interface* - ability for devs to add native language functions if needed (dart/c depending on what i choose to implement this on eventually)


[1] We could go farther and report warnings for code that isn’t necessarily wrong but probably isn’t useful. For example, many IDEs will warn if you have unreachable code after a return statement, or a local variable whose value is never read. All of that would be pretty easy to add to our static visiting pass, or as separate passes.
