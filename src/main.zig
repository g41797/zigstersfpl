const std       = @import("std");
const String    = []const u8;
const Strings    = []String;
const ArrayList = std.ArrayList;
const Lines     = ArrayList([]u8);

pub fn main() !void {

    var gpa         = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const cwd_path      = std.fs.cwd().realpathAlloc(allocator, ".") catch |err| return err;
        defer allocator.free(cwd_path);

    var paths   = [_]String{ cwd_path, "src/firstlang.log" };
    const file_path     = try std.fs.path.join(allocator, &paths);
        defer allocator.free(file_path);

    std.debug.print("\n\n", .{});

    _ = try process(allocator, file_path);

    std.debug.print("\n\n", .{});

    return;
}

pub fn process(allocator: std.mem.Allocator, file_path: []const u8) !void {

    const strings: Strings  = try collect(allocator, file_path);
        defer {
            for (strings) |str| {allocator.free(str);}
            allocator.free(strings);
    }

    const stdout_file   = std.io.getStdOut().writer();
    var bw              = std.io.bufferedWriter(stdout_file);
    const out           = bw.writer();

    for(strings) |string| {
        try out.print("{s}\n", .{string});
    }

    try bw.flush();

    return;
}

pub fn collect(allocator: std.mem.Allocator, file_path: []const u8) !Strings {

    var lines   = Lines.init(allocator);

        defer {
            for (lines.items) |l| {allocator.free(l);}
            lines.deinit();
        }

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf_reader      = std.io.bufferedReader(file.reader());
    var in_stream       = buf_reader.reader();
    var buf: [256]u8    = undefined;

    //--------------------------------------------------------------------------------
    // https://ziggit.dev/t/understanding-how-to-properly-append-to-an-arraylist/339/2
    //--------------------------------------------------------------------------------
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            const lang_info = try std.fmt.allocPrint(allocator, "{s}", .{line});
            errdefer allocator.free(lang_info);
            try lines.append(lang_info);
    }

    return lines.toOwnedSlice();
}


test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
