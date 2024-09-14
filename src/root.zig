const std = @import("std");
const testing = std.testing;
const main = @import("main.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
