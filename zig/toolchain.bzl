"""Defines the zig_toolchain rule."""

ZigInfo = provider(
    doc = "Information about the Zig compiler.",
    fields = {
        "zig_exe": "File: The Zig compiler executable.",
        "zig_version": "string: The Zig version.",
    },
)

def _zig_toolchain_impl(ctx):
    zig_info = ZigInfo(
        zig_exe = ctx.file.zig_exe,
        zig_version = ctx.attr.zig_version,
    )

    return [platform_common.ToolchainInfo(
        zig_info = zig_info,
    )]

zig_toolchain = rule(
    implementation = _zig_toolchain_impl,
    attrs = {
        "zig_exe": attr.label(
            doc = "The Zig compiler executable.",
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "zig_version": attr.string(
            doc = "The Zig version string.",
            mandatory = True,
        ),
    },
    doc = "Defines a Zig compiler toolchain.",
)
