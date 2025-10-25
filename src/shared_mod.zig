const Response = struct {
    const User = struct {
        id: u32,
        name: []const u8,
    };

    hello_world: []const u8,
    users: []const User,
};

pub const response: Response = @import("asset/response.zon");
pub const port = 80;
