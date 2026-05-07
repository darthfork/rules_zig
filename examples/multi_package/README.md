# Multi-package example

This example shows a `zig_binary` in one Bazel package depending on a `zig_library` in another package.

Build it with:

```bash
bazel build //examples/multi_package/app:hello_multi_package
```
