const std = @import("std");
const deps = @import("./deps.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.option(std.builtin.Mode, "mode", "") orelse .Debug;
    const disable_llvm = b.option(bool, "disable_llvm", "use the non-llvm zig codegen") orelse false;

    const exe_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = mode,
    });
    deps.addAllTo(exe_tests);
    exe_tests.use_llvm = !disable_llvm;
    exe_tests.use_lld = !disable_llvm;

    const tests_run = b.addRunArtifact(exe_tests);
    tests_run.has_side_effects = true;

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&tests_run.step);
}
