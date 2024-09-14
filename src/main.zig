const std = @import("std");
const testing = std.testing;
const String = []const u8;
const Strings = []String;
const Langs = []FirstLang;
const ArrayList = std.ArrayList;
const Lines = ArrayList([]u8);
const Order = std.math.Order;

pub const FirstLang = struct {
    name: [32:0]u8 = undefined,
    len: usize = 0,
    year: ?u16 = null,
    zigsters: u16 = 0,

    pub fn clear(fl: *FirstLang) void {
        fl.year = null;
        fl.zigsters = 0;
        @memset(&fl.name, 0);
        fl.len = 0;
    }

    pub fn setname(fl: *FirstLang, name: String) void {
        const dst = fl.name[0..name.len];
        @memcpy(dst, name);
        fl.len = name.len;
        return;
    }
};

fn alreadyAscNameOrder(context: void, a: FirstLang, b: FirstLang) bool {
    _ = context;

    const aname = a.name[0..a.len];
    const bname = b.name[0..b.len];

    const order = std.mem.order(u8, aname, bname);

    return !(order == .gt);
}

fn alreadyAscOrder(context: void, a: FirstLang, b: FirstLang) bool {
    _ = context;

    const aname = a.name[0..a.len];
    const bname = b.name[0..b.len];

    const order = std.mem.order(u8, aname, bname);

    if ((a.year == null) and (b.year == null)) {
        return !(order == .gt);
    }

    if (a.year == null) {
        return false;
    }

    if (b.year == null) {
        return true;
    }

    if (a.year.? == b.year.?) {
        return !(order == .gt);
    }

    return (a.year.? < b.year.?);
}

fn alreadyDscZgsOrder(context: void, a: FirstLang, b: FirstLang) bool {
    _ = context;

    const aname = a.name[0..a.len];
    const bname = b.name[0..b.len];

    if(a.zigsters == b.zigsters) {
        const order = std.mem.order(u8, aname, bname);
        return !(order == .gt);
    }

    return (a.zigsters > b.zigsters);
}


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

pub fn compute(allocator: std.mem.Allocator, langs: Langs) !Langs {

    var larr = ArrayList(FirstLang).init(allocator);
    defer larr.deinit();

    var lookup = std.StringHashMap(u16).init(allocator);

    defer {
        var it = lookup.iterator();
        while (it.next()) |kv| {
            allocator.free(kv.key_ptr.*);
        }
        lookup.deinit();
    }

    for (langs) |fl| {
        const name: []const u8 = fl.name[0..fl.len];

        const flptr = lookup.getPtr(name);
        if(flptr == null) {
            try lookup.put(try allocator.dupe(u8, name), 1);
        } else {
            flptr.?.* += @as(u16,1);
        }
    }

    var it = lookup.iterator();
    while (it.next()) |kv| {
        var fl: FirstLang = .{};
        fl.clear();
        fl.setname(kv.key_ptr.*);
        fl.zigsters = kv.value_ptr.*;
        try larr.append(fl);
    }

    const comp = larr.toOwnedSlice();
    return comp;
}

pub fn print(allocator: std.mem.Allocator, langs: Langs) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const out = bw.writer();

    std.sort.insertion(FirstLang, langs, {}, alreadyAscOrder);

    var lastWithYear: FirstLang = .{};

    for (langs, 0..langs.len) |fl, indx| {
        if (fl.year == null) {
            lastWithYear = langs[indx - 1];
            break;
        }
    }

    const langNames = try allocator.dupe(FirstLang, langs);
    defer {
        allocator.free(langNames);
    }

    std.sort.insertion(FirstLang, langNames, {}, alreadyAscNameOrder);

    const cmpNames = try compute(allocator, langNames);
    defer {
        allocator.free(cmpNames);
    }

    std.sort.insertion(FirstLang, cmpNames, {}, alreadyAscNameOrder);

    std.sort.insertion(FirstLang, cmpNames, {}, alreadyDscZgsOrder);

    try out.print("Participated: {d} Zigsters.\n", .{langs.len});
    try out.print("Winner: {s} used by {d} Zigsters.\n", .{ cmpNames[0].name[0..cmpNames[0].len],  cmpNames[0].zigsters});
    try out.print("Oldest: {1s} {0d}.\n", .{ langs[0].year.?, langs[0].name[0..langs[0].len] });
    try out.print("Newest: {1s} {0d}.\n", .{ lastWithYear.year.?, lastWithYear.name[0..lastWithYear.len] });
    try out.print("\n\n", .{});

    for (cmpNames) |fl| {
        const name = fl.name[0..fl.len];
        try out.print("{s}\t\t{d}\n", .{ name, fl.zigsters });
    }
    try out.print("\n\n", .{});

    try bw.flush();

    return;
}

pub fn printlang(fl: FirstLang, out: anytype) !void {
    if (fl.year == null) {
        try out.print("\t", .{});
    } else {
        try out.print("{d}\t", .{fl.year.?});
    }

    const name = fl.name[0..fl.len];

    try out.print("{s}\t\t", .{name});

    try out.print("{d}\n", .{fl.zigsters});

    return;
}

test "run test" {
    _ = try run();
}

test "cmp test" {
    const any: void = undefined;

    var la: FirstLang = .{};
    la.setname("12345");
    var lb: FirstLang = .{};
    lb.setname("12345");
    try testing.expect(alreadyAscOrder(any, la, lb));

    la.setname("1234");
    try testing.expect(alreadyAscOrder(any, la, lb));

    lb.setname("123");
    try testing.expect(!alreadyAscOrder(any, la, lb));

    la.setname("123");
    la.year = 2024;
    try testing.expect(alreadyAscOrder(any, la, lb));

    la.year = null;
    lb.year = 2024;
    try testing.expect(!alreadyAscOrder(any, la, lb));

    la.year = 2024;
    try testing.expect(alreadyAscOrder(any, la, lb));

    lb.setname("12");
    try testing.expect(!alreadyAscOrder(any, la, lb));

    lb.year = 2025;
    try testing.expect(alreadyAscOrder(any, la, lb));
}
