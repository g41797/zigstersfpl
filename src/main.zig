const std = @import("std");
const testing = std.testing;
const String = []const u8;
const Strings = []String;
const Langs = []FirstLang;
const ArrayList = std.ArrayList;
const Lines = ArrayList([]u8);

pub const FirstLang = struct {
    name: [32:0]u8 = undefined,
    len: usize = undefined,
    year: ?u16 = undefined,
    zigsters: u16 = undefined,

    pub fn clear(fl: *FirstLang) void {
        fl.year = null;
        fl.zigsters = 0;
        @memset(&fl.name, 0);
        fl.len = 0;
    }
};

pub fn main() !void {
    _ = try run();
    return;
}

pub fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const cwd_path = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(cwd_path);

    var paths = [_]String{ cwd_path, "src/firstlang.log" };
    const file_path = try std.fs.path.join(allocator, &paths);
    defer allocator.free(file_path);

    _ = try process(allocator, file_path);

    return;
}

pub fn process(allocator: std.mem.Allocator, file_path: []const u8) !void {
    const strings: Strings = try collect(allocator, file_path);
    defer {
        for (strings) |str| {
            allocator.free(str);
        }
        allocator.free(strings);
    }

    const langs = try parse(allocator, strings);
    defer {
        allocator.free(langs);
    }

    _ = try print(allocator, langs);

    return;
}

pub fn collect(allocator: std.mem.Allocator, file_path: []const u8) !Strings {
    var lines = Lines.init(allocator);

    defer {
        for (lines.items) |l| {
            allocator.free(l);
        }
        lines.deinit();
    }

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [256]u8 = undefined;

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

pub fn parse(allocator: std.mem.Allocator, strings: Strings) !Langs {
    var larr = ArrayList(FirstLang).init(allocator);

    defer larr.deinit();

    for (strings) |string| {
        const len = string.len;

        if (len == 0) {
            continue;
        }

        var fl: FirstLang = .{};
        fl.clear();

        const comma_index = std.mem.indexOf(u8, string, ",");

        var dst: []u8 = &fl.name;

        if (comma_index == null) {
            @memcpy(dst[0..len], string[0..len]);
            fl.len = len;
        } else {
            @memcpy(dst[0..comma_index.?], string[0..comma_index.?]);
            fl.year = try std.fmt.parseInt(u16, string[((comma_index.?) + 1)..], 10);
            fl.len = comma_index.?;
        }

        fl.zigsters = 1;

        try larr.append(fl);
    }

    return larr.toOwnedSlice();
}

pub fn print(allocator: std.mem.Allocator, langs: Langs) !void {

    _ = allocator;

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const out = bw.writer();

    for (langs) |fl| {
        const name = fl.name[0..fl.len];
        try out.print("{s} ", .{name});
        if (fl.year == null) {
            try out.print(" N/A ", .{});
        } else {
            try out.print(" {d} ", .{fl.year.?});
        }
        try out.print(" {d} \n", .{fl.zigsters});
    }

    try bw.flush();

    return;
}

test "run test" {
    _ = try run();
}
