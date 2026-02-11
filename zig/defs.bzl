"""Public API for rules_zig."""

load("//zig:rules.bzl", _zig_binary = "zig_binary", _zig_library = "zig_library")

zig_binary = _zig_binary
zig_library = _zig_library
