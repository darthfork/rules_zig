const std = @import("std");
const greeter = @import("greeter");

pub fn render(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "{s}, {s}!", .{ greeter.greet(name), name });
}
