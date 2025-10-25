const std = @import("std");
const shared_mod = @import("shared_mod");
const httpz = @import("httpz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var server = try httpz.Server(void).init(allocator, .{
        .port = shared_mod.port,
        .address = "0.0.0.0",
    }, {});
    defer {
        server.stop();
        server.deinit();
    }
    var router = try server.router(.{});

    router.get("/", root, .{});
    router.get("/httpz", httpz_endpoint, .{});
    router.get("/api/users", users, .{});
    router.get("/api/users/:id", user, .{});

    std.debug.print("Started on port {d}\n", .{shared_mod.port});
    try server.listen();
}

fn root(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = shared_mod.response.hello_world;
}

fn httpz_endpoint(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = "OK";
}

fn users(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    try res.json(shared_mod.response.users, .{});
}

fn user(req: *httpz.Request, res: *httpz.Response) !void {
    const id = std.fmt.parseInt(u32, req.param("id") orelse "0", 10) catch 0;

    if (id == 0 or id > shared_mod.response.users.len) {
        res.status = 400;
        return res.json(.{ .message = "Invalid ID" }, .{});
    }

    res.status = 200;
    try res.json(shared_mod.response.users[id - 1], .{});
}
