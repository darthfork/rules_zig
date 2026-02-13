"""Module extension for setting up the Zig toolchain."""

load("//zig/private:zig_repository.bzl", "zig_repository")
load("//zig/private:zig_toolchains_repo.bzl", "zig_toolchains_repo")

_ZIG_PLATFORMS = {
    "macos-aarch64": struct(
        os_constraint = "@platforms//os:macos",
        cpu_constraint = "@platforms//cpu:aarch64",
        index_key = "aarch64-macos",
    ),
    "macos-x86_64": struct(
        os_constraint = "@platforms//os:macos",
        cpu_constraint = "@platforms//cpu:x86_64",
        index_key = "x86_64-macos",
    ),
    "linux-x86_64": struct(
        os_constraint = "@platforms//os:linux",
        cpu_constraint = "@platforms//cpu:x86_64",
        index_key = "x86_64-linux",
    ),
    "linux-aarch64": struct(
        os_constraint = "@platforms//os:linux",
        cpu_constraint = "@platforms//cpu:aarch64",
        index_key = "aarch64-linux",
    ),
}

def _zig_impl(ctx):
    zig_version = None
    for mod in ctx.modules:
        for toolchain_tag in mod.tags.toolchain:
            if mod.is_root or zig_version == None:
                zig_version = toolchain_tag.zig_version

    if not zig_version:
        fail("No zig.toolchain() tag was specified. " +
             "Add zig.toolchain(zig_version = \"0.13.0\") to your MODULE.bazel.")

    toolchain_names = []
    toolchain_repo_names = []
    os_constraints = []
    cpu_constraints = []

    for platform_key, platform_info in _ZIG_PLATFORMS.items():
        repo_name = "zig_{}".format(platform_key.replace("-", "_"))

        zig_repository(
            name = repo_name,
            zig_version = zig_version,
            platform = platform_key,
            index_key = platform_info.index_key,
        )

        toolchain_names.append("zig_toolchain_" + platform_key.replace("-", "_"))
        toolchain_repo_names.append(repo_name)
        os_constraints.append(platform_info.os_constraint)
        cpu_constraints.append(platform_info.cpu_constraint)

    zig_toolchains_repo(
        name = "zig_toolchains",
        toolchain_names = toolchain_names,
        toolchain_repo_names = toolchain_repo_names,
        os_constraints = os_constraints,
        cpu_constraints = cpu_constraints,
    )

_toolchain_tag = tag_class(
    attrs = {
        "zig_version": attr.string(
            doc = "The Zig version to download.",
            mandatory = True,
        ),
    },
)

zig = module_extension(
    implementation = _zig_impl,
    tag_classes = {
        "toolchain": _toolchain_tag,
    },
)
