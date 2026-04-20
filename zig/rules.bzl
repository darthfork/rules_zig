"""Zig build rules."""

ZigLibraryInfo = provider(
    doc = "Information about a compiled Zig library.",
    fields = {
        "archive": "File: The compiled static library archive (.a).",
        "archives": "depset of File: This library archive plus transitive dependency archives.",
        "main_src": "File: The root Zig source file for this module.",
        "module_dep_graph": "dict(string, list[string]): Transitive module to direct-import dependencies.",
        "module_name": "string: Import name exposed for this library.",
        "modules": "dict(string, File): Transitive import-name to root-source mapping.",
        "srcs": "depset of File: The original Zig source files, including transitive dependency sources.",
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

def _collect_dep_info(deps):
    modules = {}
    module_dep_graph = {}
    transitive_srcs = []
    transitive_archives = []

    for dep in deps:
        dep_info = dep[ZigLibraryInfo]
        transitive_srcs.append(dep_info.srcs)
        transitive_archives.append(dep_info.archives)
        for module_name, module_src in dep_info.modules.items():
            existing = modules.get(module_name)
            if existing and existing.path != module_src.path:
                fail("duplicate Zig module name '{}' provided by dependencies".format(module_name))
            modules[module_name] = module_src
        for module_name, module_deps in dep_info.module_dep_graph.items():
            existing = module_dep_graph.get(module_name)
            if existing and existing != module_deps:
                fail("conflicting dependency graph for Zig module '{}'".format(module_name))
            module_dep_graph[module_name] = module_deps

    return modules, module_dep_graph, transitive_srcs, transitive_archives

def _add_module_args(args, dep_modules, module_dep_graph):
    emitted = {}

    for _ in dep_modules.keys():
        progressed = False
        for module_name in sorted(dep_modules.keys()):
            if module_name in emitted:
                continue

            ready = True
            for dep in module_dep_graph.get(module_name, []):
                if dep not in emitted:
                    ready = False
                    break

            if ready:
                for dep in module_dep_graph.get(module_name, []):
                    args.add("--dep")
                    args.add(dep)
                args.add("-M{}={}".format(module_name, dep_modules[module_name].path))
                emitted[module_name] = True
                progressed = True

        if len(emitted) == len(dep_modules):
            return
        if not progressed:
            fail("cyclic Zig module dependencies detected in deps")

def _add_common_args(args, main_src, out, cache_dir, global_cache_dir, root_deps, dep_modules, module_dep_graph, dep_archives):
    for module_name in root_deps:
        args.add("--dep")
        args.add(module_name)
    args.add("-Mroot=" + main_src.path)
    _add_module_args(args, dep_modules, module_dep_graph)
    for archive in dep_archives:
        args.add(archive.path)
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
    dep_modules, module_dep_graph, transitive_srcs, transitive_archives = _collect_dep_info(ctx.attr.deps)
    root_deps = [dep[ZigLibraryInfo].module_name for dep in ctx.attr.deps]
    dep_archives = depset(transitive = transitive_archives).to_list()

    args = ctx.actions.args()
    args.add("build-exe")
    _add_common_args(args, main_src, out, cache_dir, global_cache_dir, root_deps, dep_modules, module_dep_graph, dep_archives)

    ctx.actions.run(
        outputs = [out, cache_dir, global_cache_dir],
        inputs = depset(srcs, transitive = transitive_srcs + transitive_archives),
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
        "deps": attr.label_list(
            doc = "Zig libraries to make available as imports and link inputs.",
            providers = [ZigLibraryInfo],
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
    dep_modules, module_dep_graph, transitive_srcs, transitive_archives = _collect_dep_info(ctx.attr.deps)
    root_deps = [dep[ZigLibraryInfo].module_name for dep in ctx.attr.deps]

    module_name = ctx.attr.module_name or ctx.label.name
    existing = dep_modules.get(module_name)
    if existing and existing.path != main_src.path:
        fail("module name '{}' conflicts with a dependency".format(module_name))

    args = ctx.actions.args()
    args.add("build-lib")
    _add_common_args(args, main_src, out, cache_dir, global_cache_dir, root_deps, dep_modules, module_dep_graph, depset(transitive = transitive_archives).to_list())

    ctx.actions.run(
        outputs = [out, cache_dir, global_cache_dir],
        inputs = depset(srcs, transitive = transitive_srcs + transitive_archives),
        executable = zig_exe,
        arguments = [args],
        mnemonic = "ZigCompileLib",
        progress_message = "Compiling Zig library %{label}",
    )

    return [
        DefaultInfo(files = depset([out])),
        ZigLibraryInfo(
            archive = out,
            archives = depset([out], transitive = transitive_archives),
            main_src = main_src,
            module_dep_graph = dict(module_dep_graph, **{module_name: root_deps}),
            module_name = module_name,
            modules = dict(dep_modules, **{module_name: main_src}),
            srcs = depset(srcs, transitive = transitive_srcs),
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
        "module_name": attr.string(
            doc = "Import name exposed to dependents. Defaults to the target name.",
        ),
        "deps": attr.label_list(
            doc = "Other zig_library targets this library imports or links.",
            providers = [ZigLibraryInfo],
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
