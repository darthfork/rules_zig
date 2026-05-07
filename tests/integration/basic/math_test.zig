const std = @import("std");
const math = @import("math.zig");

test "math helpers return expected values" {
    try std.testing.expectEqual(@as(i32, 5), math.add(2, 3));
    try std.testing.expectEqual(@as(i32, 42), math.multiply(6, 7));
}
