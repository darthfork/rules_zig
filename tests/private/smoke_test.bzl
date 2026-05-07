"""Small test-only smoke test rule for executable Zig targets."""

def _binary_smoke_test_impl(ctx):
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    binary = ctx.executable.binary
    ctx.actions.write(
        output = script,
        is_executable = True,
        content = """#!/usr/bin/env bash
set -euo pipefail
runfiles_dir="${RUNFILES_DIR:-$0.runfiles}"
"${runfiles_dir}/${TEST_WORKSPACE}/%s"
""" % binary.short_path,
    )

    return [
        DefaultInfo(
            executable = script,
            runfiles = ctx.runfiles(files = [binary]),
        ),
    ]

def _build_smoke_test_impl(ctx):
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = script,
        is_executable = True,
        content = "#!/usr/bin/env bash\nset -euo pipefail\n",
    )
    return [
        DefaultInfo(
            executable = script,
            runfiles = ctx.runfiles(files = ctx.files.target),
        ),
    ]

binary_smoke_test = rule(
    implementation = _binary_smoke_test_impl,
    attrs = {
        "binary": attr.label(
            doc = "Executable target to run as a smoke test.",
            cfg = "target",
            executable = True,
            mandatory = True,
        ),
    },
    test = True,
)

build_smoke_test = rule(
    implementation = _build_smoke_test_impl,
    attrs = {
        "target": attr.label(
            doc = "Target whose default outputs must build.",
            mandatory = True,
        ),
    },
    test = True,
)
