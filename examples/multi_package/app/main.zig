const std = @import("std");
const greeting = @import("greeting");

pub fn main() !void {
    try std.io.getStdOut().writer().print("{s}\n", .{greeting.text()});
}
