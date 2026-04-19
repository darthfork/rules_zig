"""Zig build rules."""

ZigLibraryInfo = provider(
    doc = "Information about a compiled Zig library.",
    fields = {
        "archive": "File: The compiled static library archive (.a).",
        "srcs": "depset of File: The original Zig source files.",
    },
)

def _select_main_src(srcs, main, rule_name):
    if len(srcs) == 0:
        fail("{} requires at least one source file in srcs.".format(rule_name))

    if main:
        for src in srcs:
            if src.basename == main or src.short_path.endswith(main):
                return src
        fail("main file '{}' not found in srcs.".format(main))

    return srcs[0]

def _declare_cache_dirs(ctx):
    return (
        ctx.actions.declare_directory(ctx.label.name + "_cache"),
        ctx.actions.declare_directory(ctx.label.name + "_global_cache"),
    )

def _add_common_args(args, main_src, out, cache_dir, global_cache_dir):
    args.add(main_src)
    args.add("-femit-bin=" + out.path)
    args.add("--cache-dir")
    args.add(cache_dir.path)
    args.add("--global-cache-dir")
    args.add(global_cache_dir.path)

def _zig_binary_impl(ctx):
    zig_toolchain = ctx.toolchains["//zig:toolchain_type"]
    zig_info = zig_toolchain.zig_info
    zig_exe = zig_info.zig_exe

    out = ctx.actions.declare_file(ctx.label.name)
    cache_dir, global_cache_dir = _declare_cache_dirs(ctx)

    srcs = ctx.files.srcs
    main_src = _select_main_src(srcs, ctx.attr.main, "zig_binary")

    args = ctx.actions.args()
    args.add("build-exe")
    _add_common_args(args, main_src, out, cache_dir, global_cache_dir)

    ctx.actions.run(
        outputs = [out, cache_dir, global_cache_dir],
        inputs = srcs,
        executable = zig_exe,
        arguments = [args],
        mnemonic = "ZigCompile",
        progress_message = "Compiling Zig binary %{label}",
    )

    return [
        DefaultInfo(
            files = depset([out]),
            executable = out,
        ),
    ]

zig_binary = rule(
    implementation = _zig_binary_impl,
    attrs = {
        "srcs": attr.label_list(
            doc = "Zig source files to compile.",
            allow_files = [".zig"],
            mandatory = True,
        ),
        "main": attr.string(
            doc = "The main source file to compile. Defaults to the first file in srcs.",
        ),
    },
    executable = True,
    toolchains = ["//zig:toolchain_type"],
)

def _zig_library_impl(ctx):
    zig_toolchain = ctx.toolchains["//zig:toolchain_type"]
    zig_info = zig_toolchain.zig_info
    zig_exe = zig_info.zig_exe

    out = ctx.actions.declare_file("lib" + ctx.label.name + ".a")
    cache_dir, global_cache_dir = _declare_cache_dirs(ctx)

    srcs = ctx.files.srcs
    main_src = _select_main_src(srcs, ctx.attr.main, "zig_library")

    args = ctx.actions.args()
    args.add("build-lib")
    _add_common_args(args, main_src, out, cache_dir, global_cache_dir)

    ctx.actions.run(
        outputs = [out, cache_dir, global_cache_dir],
        inputs = srcs,
        executable = zig_exe,
        arguments = [args],
        mnemonic = "ZigCompileLib",
        progress_message = "Compiling Zig library %{label}",
    )

    return [
        DefaultInfo(files = depset([out])),
        ZigLibraryInfo(
            archive = out,
            srcs = depset(srcs),
        ),
    ]

zig_library = rule(
    implementation = _zig_library_impl,
    attrs = {
        "srcs": attr.label_list(
            doc = "Zig source files to compile.",
            allow_files = [".zig"],
            mandatory = True,
        ),
        "main": attr.string(
            doc = "The root source file for the library. Defaults to the first file in srcs.",
        ),
    },
    toolchains = ["//zig:toolchain_type"],
)

def _zig_test_impl(ctx):
    zig_toolchain = ctx.toolchains["//zig:toolchain_type"]
    zig_info = zig_toolchain.zig_info
    zig_exe = zig_info.zig_exe

    srcs = ctx.files.srcs
    main_src = _select_main_src(srcs, ctx.attr.main, "zig_test")

    out = ctx.actions.declare_file(ctx.label.name)
    src_tree = ctx.actions.declare_directory(ctx.label.name + "_srcs")
    zig_link = ctx.actions.declare_file(ctx.label.name + "_zig")
    cache_dir, global_cache_dir = _declare_cache_dirs(ctx)

    ctx.actions.symlink(
        output = zig_link,
        target_file = zig_exe,
        is_executable = True,
    )

    copy_commands = []
    for src in srcs:
        copy_commands.append("cp '{}' '{}/{}'".format(src.path, src_tree.path, src.basename))

    command = "set -euo pipefail\nROOT=\"$PWD\"\nmkdir -p '{src_tree}' '{cache_dir}' '{global_cache_dir}'\n{copies}\ncd '{src_tree}'\n\"$ROOT/{zig}\" test '{main}' -femit-bin=\"$ROOT/{out}\" --cache-dir \"$ROOT/{cache_dir}\" --global-cache-dir \"$ROOT/{global_cache_dir}\"".format(
        src_tree = src_tree.path,
        cache_dir = cache_dir.path,
        global_cache_dir = global_cache_dir.path,
        copies = "\n".join(copy_commands),
        zig = zig_link.path,
        main = main_src.basename,
        out = out.path,
    )

    ctx.actions.run_shell(
        outputs = [out, src_tree, cache_dir, global_cache_dir],
        inputs = srcs + [zig_link],
        command = command,
        mnemonic = "ZigCompileTest",
        progress_message = "Compiling Zig test %{label}",
    )

    return [
        DefaultInfo(
            files = depset([out]),
            executable = out,
        ),
    ]

zig_test = rule(
    implementation = _zig_test_impl,
    attrs = {
        "srcs": attr.label_list(
            doc = "Zig test source files to compile.",
            allow_files = [".zig"],
            mandatory = True,
        ),
        "main": attr.string(
            doc = "The root source file for the test. Defaults to the first file in srcs.",
        ),
    },
    test = True,
    toolchains = ["//zig:toolchain_type"],
)
