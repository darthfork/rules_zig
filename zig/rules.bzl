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
