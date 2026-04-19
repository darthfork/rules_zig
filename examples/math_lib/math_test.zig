const std = @import("std");
const math = @import("math.zig");

test "basic arithmetic helpers" {
    try std.testing.expectEqual(@as(i32, 5), math.add(2, 3));
    try std.testing.expectEqual(@as(i32, 6), math.multiply(2, 3));
    try std.testing.expectEqual(@as(i32, -1), math.subtract(2, 3));
}
