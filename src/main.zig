const std = @import("std");
const bench_zig_web_frameworks = @import("bench_zig_web_frameworks");
const shared_mod = @import("./shared_mod.zig");

pub fn main() !void {
    std.debug.print("{s}\n", .{shared_mod.response.hello_world});
    try bench_zig_web_frameworks.bufferedPrint();
}
