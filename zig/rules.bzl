"""Zig build rules."""

ZigLibraryInfo = provider(
    doc = "Information about a compiled Zig library.",
    fields = {
        "archive": "File: The compiled static library archive (.a).",
        "srcs": "depset of File: The original Zig source files.",
    },
)

def _zig_binary_impl(ctx):
    zig_toolchain = ctx.toolchains["//zig:toolchain_type"]
    zig_info = zig_toolchain.zig_info
    zig_exe = zig_info.zig_exe

    out = ctx.actions.declare_file(ctx.label.name)

    srcs = ctx.files.srcs
    if len(srcs) == 0:
        fail("zig_binary requires at least one source file in srcs.")

    # Determine the main source file.
    main_src = None
    if ctx.attr.main:
        for src in srcs:
            if src.short_path.endswith(ctx.attr.main):
                main_src = src
                break
        if not main_src:
            fail("main file '{}' not found in srcs.".format(ctx.attr.main))
    else:
        main_src = srcs[0]

    args = ctx.actions.args()
    args.add("build-exe")
    args.add(main_src)
    args.add("-femit-bin=" + out.path)
    args.add("--cache-dir")
    args.add("/tmp/zig-cache")
    args.add("--global-cache-dir")
    args.add("/tmp/zig-global-cache")

    ctx.actions.run(
        outputs = [out],
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

    srcs = ctx.files.srcs
    if len(srcs) == 0:
        fail("zig_library requires at least one source file in srcs.")

    main_src = None
    if ctx.attr.main:
        for src in srcs:
            if src.short_path.endswith(ctx.attr.main):
                main_src = src
                break
        if not main_src:
            fail("main file '{}' not found in srcs.".format(ctx.attr.main))
    else:
        main_src = srcs[0]

    args = ctx.actions.args()
    args.add("build-lib")
    args.add(main_src)
    args.add("-femit-bin=" + out.path)
    args.add("--cache-dir")
    args.add("/tmp/zig-cache")
    args.add("--global-cache-dir")
    args.add("/tmp/zig-global-cache")

    ctx.actions.run(
        outputs = [out],
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
    if len(srcs) == 0:
        fail("zig_test requires at least one source file in srcs.")

    main_filename = ctx.attr.main if ctx.attr.main else srcs[0].basename
    main_src = None
    for src in srcs:
        if src.basename == main_filename or src.short_path.endswith(main_filename):
            main_src = src
            break
    if not main_src:
        fail("main file '{}' not found in srcs.".format(main_filename))

    out = ctx.actions.declare_file(ctx.label.name)
    src_tree = ctx.actions.declare_directory(ctx.label.name + "_srcs")
    zig_link = ctx.actions.declare_file(ctx.label.name + "_zig")

    ctx.actions.symlink(
        output = zig_link,
        target_file = zig_exe,
        is_executable = True,
    )

    copy_commands = []
    for src in srcs:
        copy_commands.append("cp '{}' '{}/{}'".format(src.path, src_tree.path, src.basename))

    command = "set -euo pipefail\nROOT=\"$PWD\"\nmkdir -p '{src_tree}'\n{copies}\ncd '{src_tree}'\n\"$ROOT/{zig}\" test '{main}' -femit-bin=\"$ROOT/{out}\" --cache-dir /tmp/zig-cache --global-cache-dir /tmp/zig-global-cache".format(
        src_tree = src_tree.path,
        copies = "\n".join(copy_commands),
        zig = zig_link.path,
        main = main_src.basename,
        out = out.path,
    )

    ctx.actions.run_shell(
        outputs = [out, src_tree],
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
