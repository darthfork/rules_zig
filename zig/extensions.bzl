"""Module extension for setting up the Zig toolchain."""

load("//zig/private:zig_repository.bzl", "zig_repository")
load("//zig/private:zig_toolchains_repo.bzl", "zig_toolchains_repo")

_ZIG_PLATFORMS = {
    "macos-aarch64": struct(
        os_constraint = "@platforms//os:macos",
        cpu_constraint = "@platforms//cpu:aarch64",
        url = "https://ziglang.org/download/{version}/zig-macos-aarch64-{version}.tar.xz",
        sha256 = "46fae219656545dfaf4dce12fb4e8685cec5b51d721beee9389ab4194d43394c",
        strip_prefix = "zig-macos-aarch64-{version}",
    ),
    "macos-x86_64": struct(
        os_constraint = "@platforms//os:macos",
        cpu_constraint = "@platforms//cpu:x86_64",
        url = "https://ziglang.org/download/{version}/zig-macos-x86_64-{version}.tar.xz",
        sha256 = "8b06ed1091b2269b700b3b07f8e3be3b833000841bae5aa6a09b1a8b4773effd",
        strip_prefix = "zig-macos-x86_64-{version}",
    ),
    "linux-x86_64": struct(
        os_constraint = "@platforms//os:linux",
        cpu_constraint = "@platforms//cpu:x86_64",
        url = "https://ziglang.org/download/{version}/zig-linux-x86_64-{version}.tar.xz",
        sha256 = "d45312e61ebcc48032b77bc4cf7fd6915c11fa16e4aad116b66c9468211230ea",
        strip_prefix = "zig-linux-x86_64-{version}",
    ),
    "linux-aarch64": struct(
        os_constraint = "@platforms//os:linux",
        cpu_constraint = "@platforms//cpu:aarch64",
        url = "https://ziglang.org/download/{version}/zig-linux-aarch64-{version}.tar.xz",
        sha256 = "041ac42323837eb5624068acd8b00cd5777dac4cf91179e8dad7a7e90dd0c556",
        strip_prefix = "zig-linux-aarch64-{version}",
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

    if zig_version != "0.13.0":
        fail("rules_zig MVP only supports Zig 0.13.0, got: " + zig_version)

    toolchain_names = []
    toolchain_repo_names = []
    os_constraints = []
    cpu_constraints = []

    for platform_key, platform_info in _ZIG_PLATFORMS.items():
        repo_name = "zig_{}".format(platform_key.replace("-", "_"))

        zig_repository(
            name = repo_name,
            urls = [platform_info.url.format(version = zig_version)],
            sha256 = platform_info.sha256,
            strip_prefix = platform_info.strip_prefix.format(version = zig_version),
            zig_version = zig_version,
            platform = platform_key,
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
