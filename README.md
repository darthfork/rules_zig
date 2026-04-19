# rules_zig

Bazel rules for building [Zig](https://ziglang.org/) projects.

## Features

- `zig_binary` — compile Zig source files into an executable
- `zig_library` — compile Zig source files into a static library (`.a`)
- Bazel toolchain integration with platform-aware compiler resolution

## Requirements

- Zig: 0.13.0
- Bazel: 9.0+

## CI and support matrix

The repository currently runs CI on:

- Bazel 9.0.1 on Linux and macOS
- Bazel 9.0.2 on Linux and macOS

This gives us coverage for the minimum supported Bazel 9 line and a newer Bazel 9 patch release that is currently available on GitHub-hosted runners.

CI currently runs:

- `bazel build //...`
- `bazel test ...` when Bazel test targets are present

As the ruleset grows, this matrix can expand to include more Bazel versions, additional examples, and stricter validation.

## Setup

### Bzlmod (MODULE.bazel)

Since `rules_zig` is not yet published to the [Bazel Central Registry](https://registry.bazel.build/), use `git_override` to depend on it directly from GitHub.

Add the following to your `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_zig", version = "0.1.0")
git_override(
    module_name = "rules_zig",
    remote = "https://github.com/darthfork/rules_zig.git",
    commit = "<commit_sha>",  # pin to a specific commit
)

zig = use_extension("@rules_zig//zig:extensions.bzl", "zig")
zig.toolchain(zig_version = "0.13.0")
use_repo(zig, "zig_toolchains")

register_toolchains("@zig_toolchains//:all")
```

Replace `<commit_sha>` with the commit you want to pin to.

### WORKSPACE

WORKSPACE is not supported. Bazel 9+ requires Bzlmod.

## Rules

### `zig_binary` example

Compiles Zig source files into an executable.

```starlark
load("@rules_zig//zig:defs.bzl", "zig_binary")

zig_binary(
    name = "hello_world",
    srcs = ["main.zig"],
)
```

| Attribute | Description | Required |
|-----------|-------------|----------|
| `srcs` | List of `.zig` source files | Yes |
| `main` | Root source file to compile. Defaults to the first file in `srcs`. | No |

### `zig_library` example

Compiles Zig source files into a static library.

```starlark
load("@rules_zig//zig:defs.bzl", "zig_library")

zig_library(
    name = "math",
    srcs = ["math.zig"],
)
```

| Attribute | Description | Required |
|-----------|-------------|----------|
| `srcs` | List of `.zig` source files | Yes |
| `main` | Root source file for the library. Defaults to the first file in `srcs`. | No |
