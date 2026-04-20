const std = @import("std");
const message = @import("message");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const text = try message.render(allocator, "Bazel");
    defer allocator.free(text);
    std.debug.print("{s}\n", .{text});
}
