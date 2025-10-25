const std = @import("std");
const shared_mod = @import("shared_mod");
const zap = @import("zap");
// const response = @embedFile("../../asset/response.zon");

fn on_request(r: zap.Request) !void {
    // std.debug.print("{}\n", .{response.hello_world});
    if (r.path) |the_path| {
        // Route handling
        if (std.mem.eql(u8, the_path, "/")) {
            r.setStatus(.ok);
            r.sendBody("Hello from zap!") catch return;
        } else if (std.mem.eql(u8, the_path, "/httpz")) {
            r.setStatus(.ok);
            r.sendBody("OK") catch return;
        } else if (std.mem.eql(u8, the_path, "/api/json")) {
            r.setStatus(.ok);
            r.sendJson("{\"message\":\"Hello from zap!\",\"framework\":\"zap\",\"success\":true}") catch return;
        } else if (std.mem.startsWith(u8, the_path, "/api/user/")) {
            const id = the_path[10..]; // Extract ID from path after "/api/user/"
            r.setStatus(.ok);
            var buf: [256]u8 = undefined;
            const json = std.fmt.bufPrint(&buf, "{{\"id\":\"{s}\",\"name\":\"User\",\"framework\":\"zap\"}}", .{id}) catch return;
            r.sendJson(json) catch return;
        } else {
            r.setStatus(.not_found);
            r.sendBody("Not Found") catch return;
        }
    }
}

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = shared_mod.port,
        .on_request = on_request,
        .log = false,
    });
    try listener.listen();

    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
