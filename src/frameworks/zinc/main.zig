const std = @import("std");
const shared_mod = @import("shared_mod");
const zinc = @import("zinc");

pub fn main() !void {
    var z = try zinc.init(.{
        .port = shared_mod.port,
        .num_threads = 4,
        .force_nonblocking = true,
    });
    defer z.deinit();

    var router = z.getRouter();

    try router.get("/", root);
    try router.get("/httpz", httpzEndpoint);
    try router.get("/api/users/:id", user);
    try router.get("/api/users", users);

    try z.run();
}

fn root(ctx: *zinc.Context) anyerror!void {
    try ctx.send(shared_mod.response.hello_world, .{});
}

fn httpzEndpoint(ctx: *zinc.Context) anyerror!void {
    try ctx.send("OK", .{});
}

fn users(ctx: *zinc.Context) anyerror!void {
    try ctx.json(shared_mod.response.users, .{});
}

fn user(ctx: *zinc.Context) anyerror!void {
    const id_param = ctx.getParam("id").?.value;
    const id = std.fmt.parseInt(u32, id_param, 10) catch 0;

    if (id == 0 or id > shared_mod.response.users.len) {
        try ctx.json(.{ .message = "Invalid ID" }, .{});
        return;
    }

    try ctx.json(shared_mod.response.users[id - 1], .{});
}
