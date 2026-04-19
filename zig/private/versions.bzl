"""Pinned Zig SDK metadata used by rules_zig."""

_ZIG_VERSIONS = {
    "0.13.0": {
        "aarch64-linux": struct(
            tarball = "https://ziglang.org/download/0.13.0/zig-linux-aarch64-0.13.0.tar.xz",
            sha256 = "041ac42323837eb5624068acd8b00cd5777dac4cf91179e8dad7a7e90dd0c556",
            strip_prefix = "zig-linux-aarch64-0.13.0",
        ),
        "aarch64-macos": struct(
            tarball = "https://ziglang.org/download/0.13.0/zig-macos-aarch64-0.13.0.tar.xz",
            sha256 = "46fae219656545dfaf4dce12fb4e8685cec5b51d721beee9389ab4194d43394c",
            strip_prefix = "zig-macos-aarch64-0.13.0",
        ),
        "x86_64-linux": struct(
            tarball = "https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz",
            sha256 = "d45312e61ebcc48032b77bc4cf7fd6915c11fa16e4aad116b66c9468211230ea",
            strip_prefix = "zig-linux-x86_64-0.13.0",
        ),
        "x86_64-macos": struct(
            tarball = "https://ziglang.org/download/0.13.0/zig-macos-x86_64-0.13.0.tar.xz",
            sha256 = "8b06ed1091b2269b700b3b07f8e3be3b833000841bae5aa6a09b1a8b4773effd",
            strip_prefix = "zig-macos-x86_64-0.13.0",
        ),
    },
}

def get_zig_sdk(version, index_key):
    version_entry = _ZIG_VERSIONS.get(version)
    if not version_entry:
        return None
    return version_entry.get(index_key)

def pinned_zig_versions():
    return sorted(_ZIG_VERSIONS.keys())
