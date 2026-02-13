# rules_zig

Bazel rules for building [Zig](https://ziglang.org/) projects.

## Features

- `zig_binary` — compile Zig source files into an executable
- `zig_library` — compile Zig source files into a static library (`.a`)
- Bazel toolchain integration with platform-aware compiler resolution

## Requirements

- Bazel 9.0+

## Setup

### Bzlmod (MODULE.bazel)

Add the following to your `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_zig", version = "0.1.0")

zig = use_extension("@rules_zig//zig:extensions.bzl", "zig")
zig.toolchain(zig_version = "0.13.0")
use_repo(zig, "zig_toolchains")

register_toolchains("@zig_toolchains//:all")
```

### WORKSPACE

WORKSPACE is not supported. Bazel 9+ requires Bzlmod.

## Rules

### `zig_binary`

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

### `zig_library`

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


## Supported Zig Versions

- 0.13.0
