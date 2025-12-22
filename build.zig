const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zuo_dep = b.dependency("zuo", .{});

    const boot_zuo_exe = b.addExecutable(.{
        .name = "boot-zuo",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .strip = false,
            .optimize = .Debug,
            .target = b.graph.host,
        }),
    });

    boot_zuo_exe.root_module.link_libc = true;
    boot_zuo_exe.root_module.addCSourceFiles(.{
        .root = zuo_dep.path(""),
        .files = &.{"zuo.c"},
    });

    const boot_zuo_run = b.addRunArtifact(boot_zuo_exe);
    boot_zuo_run.addFileArg(zuo_dep.path("local/image.zuo"));
    boot_zuo_run.setEnvironmentVariable("ZUO_LIB_PATH", zuo_dep.path("lib").getPath2(b, null));
    const embedded_zuo = boot_zuo_run.captureStdOut();

    const zuo = b.addExecutable(.{
        .name = "zuo",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .optimize = optimize,
            .strip = optimize != .Debug,
            .target = target,
        }),
    });
    zuo.step.dependOn(&boot_zuo_run.step);
    zuo.root_module.link_libc = true;
    zuo.root_module.addCSourceFiles(.{
        .language = .c,
        .root = embedded_zuo.dirname(),
        .files = &.{"stdout"}, // depends on captureStdOut() file naming
    });
    b.installArtifact(zuo);
}
