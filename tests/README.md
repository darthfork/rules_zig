# rules_zig tests

This tree contains regression coverage for the ruleset itself.

- `integration/basic` verifies that `zig_binary`, `zig_library`, and `zig_test` all work under `bazel test`.
- `private` contains small Starlark helpers used only by the test suite.

Run everything with:

```bash
bazel test //...
```
