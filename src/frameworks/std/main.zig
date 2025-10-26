const std = @import("std");
const shared_mod = @import("shared_mod");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var thread_pool: std.Thread.Pool = undefined;
    try thread_pool.init(.{
        .allocator = allocator,
        .n_jobs = shared_mod.thread_count,
    });
    defer thread_pool.deinit();

    const address = try std.net.Address.parseIp4("0.0.0.0", shared_mod.port);

    var server = try address.listen(std.net.Address.ListenOptions{});
    defer server.deinit();

    std.debug.print("Started on port {d}\n", .{5000});
    while (true) {
        const conn = try server.accept();
        errdefer conn.stream.close();

        try thread_pool.spawn(handleConnectionMain, .{conn});
    }
}

fn handleConnectionMain(connection: std.net.Server.Connection) void {
    handleConnection(connection) catch |err| {
        std.debug.print("Error: {}\n", .{err});
    };
}

fn handleConnection(connection: std.net.Server.Connection) !void {
    defer connection.stream.close();

    var recv_buffer: [4000]u8 = undefined;
    var send_buffer: [4000]u8 = undefined;
    var conn_reader = connection.stream.reader(&recv_buffer);
    var conn_writer = connection.stream.writer(&send_buffer);

    var server = std.http.Server.init(conn_reader.interface(), &conn_writer.interface);
    while (true) {
        var req = try server.receiveHead();
        try req.respond("OK", std.http.Server.Request.RespondOptions{});
        if (!req.head.keep_alive) break;
    }
}
