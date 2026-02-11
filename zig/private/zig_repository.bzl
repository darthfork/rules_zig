"""Repository rule for downloading a Zig SDK."""

def _zig_repository_impl(ctx):
    ctx.report_progress("Downloading Zig SDK")
    ctx.download_and_extract(
        url = ctx.attr.urls,
        sha256 = ctx.attr.sha256,
        stripPrefix = ctx.attr.strip_prefix,
    )

    zig_exe = "zig.exe" if "windows" in ctx.attr.platform else "zig"

    ctx.file(
        "BUILD.bazel",
        content = """\
load("@rules_zig//zig:toolchain.bzl", "zig_toolchain")

package(default_visibility = ["//visibility:public"])

exports_files(["{zig_exe}"])

zig_toolchain(
    name = "zig_toolchain_impl",
    zig_exe = "{zig_exe}",
    zig_version = "{zig_version}",
)
""".format(
            zig_exe = zig_exe,
            zig_version = ctx.attr.zig_version,
        ),
    )

zig_repository = repository_rule(
    implementation = _zig_repository_impl,
    attrs = {
        "urls": attr.string_list(
            doc = "URLs to download the Zig SDK archive.",
            mandatory = True,
        ),
        "sha256": attr.string(
            doc = "Expected SHA-256 hash of the archive.",
            mandatory = True,
        ),
        "strip_prefix": attr.string(
            doc = "Directory prefix to strip from the extracted archive.",
            mandatory = True,
        ),
        "zig_version": attr.string(
            doc = "The Zig version.",
            mandatory = True,
        ),
        "platform": attr.string(
            doc = "The platform identifier (e.g., 'macos-aarch64').",
            mandatory = True,
        ),
    },
    doc = "Downloads a Zig SDK for a specific platform.",
)
