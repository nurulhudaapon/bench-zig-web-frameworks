const std = @import("std");
const shared_mod = @import("shared_mod");

pub fn main() !void {
    const address = try std.net.Address.parseIp4("0.0.0.0", shared_mod.port);

    var server = try address.listen(std.net.Address.ListenOptions{});
    defer server.deinit();

    std.debug.print("Started on port {d}\n", .{shared_mod.port});
    while (true) {
        try handleConnection(try server.accept());
    }
}

fn handleConnection(connection: std.net.Server.Connection) !void {
    defer connection.stream.close();

    var recv_buffer: [4000]u8 = undefined;
    var send_buffer: [4000]u8 = undefined;
    var conn_reader = connection.stream.reader(&recv_buffer);
    var conn_writer = connection.stream.writer(&send_buffer);

    var server = std.http.Server.init(conn_reader.interface(), &conn_writer.interface);
    var req = try server.receiveHead();
    try req.respond("OK", std.http.Server.Request.RespondOptions{});
}
