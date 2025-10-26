//! A simple root module to keep the codebase structure standard.
const std = @import("std");

pub fn bufferedPrint() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("This is a benchmark suite for Zig web frameworks.\n", .{});

    try stdout.flush();
}
