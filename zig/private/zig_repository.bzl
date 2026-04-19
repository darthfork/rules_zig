"""Repository rule for downloading a pinned Zig SDK."""

load("//zig/private:versions.bzl", "get_zig_sdk", "pinned_zig_versions")

def _zig_repository_impl(ctx):
    sdk = get_zig_sdk(ctx.attr.zig_version, ctx.attr.index_key)
    if not sdk:
        fail("Unsupported Zig SDK '{} / {}'. Pinned versions: {}.".format(
            ctx.attr.zig_version,
            ctx.attr.index_key,
            ", ".join(pinned_zig_versions()),
        ))

    ctx.report_progress("Downloading Zig SDK")
    ctx.download_and_extract(
        url = [sdk.tarball],
        sha256 = sdk.sha256,
        stripPrefix = sdk.strip_prefix,
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
        "zig_version": attr.string(
            doc = "The Zig version.",
            mandatory = True,
        ),
        "platform": attr.string(
            doc = "The platform identifier (e.g., 'macos-aarch64').",
            mandatory = True,
        ),
        "index_key": attr.string(
            doc = "The arch-os key used in pinned Zig SDK metadata (e.g., 'aarch64-macos').",
            mandatory = True,
        ),
    },
    doc = "Downloads a pinned Zig SDK for a specific platform.",
)
