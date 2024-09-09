const std       = @import("std");
const testing   = std.testing;

test {
    @import("std").testing.refAllDecls(@This());
}
