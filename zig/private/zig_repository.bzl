"""Repository rule for downloading a Zig SDK."""

_ZIG_INDEX_URL = "https://ziglang.org/download/index.json"

def _zig_repository_impl(ctx):
    ctx.report_progress("Fetching Zig download index")
    index_path = ctx.path("index.json")
    ctx.download(
        url = [_ZIG_INDEX_URL],
        output = index_path,
    )
    index = json.decode(ctx.read(index_path))
    ctx.delete(index_path)

    version_entry = index.get(ctx.attr.zig_version)
    if not version_entry:
        fail("Zig version '{}' not found in the download index.".format(ctx.attr.zig_version))

    platform_entry = version_entry.get(ctx.attr.index_key)
    if not platform_entry:
        fail("Platform '{}' not found for Zig version '{}'.".format(
            ctx.attr.index_key,
            ctx.attr.zig_version,
        ))

    tarball_url = platform_entry["tarball"]
    shasum = platform_entry["shasum"]

    ctx.report_progress("Downloading Zig SDK")
    ctx.download_and_extract(
        url = [tarball_url],
        sha256 = shasum,
        stripPrefix = tarball_url.split("/")[-1].removesuffix(".tar.xz").removesuffix(".zip"),
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
            doc = "The arch-os key used in the Zig download index (e.g., 'aarch64-macos').",
            mandatory = True,
        ),
    },
    doc = "Downloads a Zig SDK for a specific platform.",
)
