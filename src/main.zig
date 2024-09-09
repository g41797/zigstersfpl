const std = @import("std");

pub fn main() !void {

    // Get an allocator.
    var gpa         = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var info = try std.fs.cwd().openFile("src/firstlang.log", .{});
    defer info.close();

    std.debug.print("Before processing.\n\n", .{});

    const stdout_file   = std.io.getStdOut().writer();
    var bw              = std.io.bufferedWriter(stdout_file);
    const out           = bw.writer();

    _ = try process(allocator, info, out);

    try bw.flush();

    std.debug.print("After processing.\n\n", .{});

    return;
}

pub fn process(_: std.mem.Allocator, _: std.fs.File, _: anytype) !void {

    return;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
