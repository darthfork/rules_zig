"""Public API for rules_zig."""

load("//zig:rules.bzl", _zig_binary = "zig_binary", _zig_library = "zig_library", _zig_test = "zig_test")

zig_binary = _zig_binary
zig_library = _zig_library
zig_test = _zig_test
