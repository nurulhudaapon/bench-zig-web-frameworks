const std = @import("std");
const shared_mod = @import("shared_mod");

pub fn main() !void {
    const address = try std.net.Address.parseIp4("0.0.0.0", shared_mod.port);

    var server = try address.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();

    std.debug.print("Started on port {d}\n", .{shared_mod.port});

    while (true) {
        const connection = try server.accept();
        handleConnection(connection) catch |err| {
            std.debug.print("Error handling connection: {}\n", .{err});
        };
    }
}

fn handleConnection(connection: std.net.Server.Connection) !void {
    defer connection.stream.close();

    var buffer: [4096]u8 = undefined;

    // Read the HTTP request
    const bytes_read = try connection.stream.read(&buffer);
    if (bytes_read == 0) return;

    // Simple HTTP response
    const response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK";
    _ = try connection.stream.writeAll(response);
}
