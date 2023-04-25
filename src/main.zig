const clap = @import("clap");
const std = @import("std");
const file = std.fs.File;

const debug = std.debug;
const io = std.io;
const process = std.process;

pub fn main() !void {
    // First we specify what parameters our program can take.
    // We can use `parseParamsComptime` to parse a string into an array of `Param(Help)`
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-c, --create
        \\-a, --add <STR>     An option parameter, which takes a value.
        \\-r, --remove <STR>  An option parameter which takes an enum.
        \\-l, --list 
        \\
    );

    // Declare our own parsers which are used to map the argument strings to other
    // types.
    // const YesNo = enum { yes, no };
    const parsers = comptime .{
        .STR = clap.parsers.string,
        .FILE = clap.parsers.string,
        // .INT = clap.parsers.int(usize, 10),
        // .ANSWER = clap.parsers.enumeration(YesNo),
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help)
        debug.print("--help\n", .{});

    if (res.args.create)
        try createFile();

    // createFile() catch |err| {
    //     debug.print("Error: {s}\n", .{err});
    //     return err;
    // };

    if (res.args.add) |s|
        try addEntry(s);

    //
    // if (res.args.remove) |s|
    //     debug.print("--remove = {s}\n", .{s});
    //
    if (res.args.list)
        try listEntries();

    // for (res.args.remove) |s|
    //     debug.print("--string = {s}\n", .{s});
    //
    // for (res.args.list)
    //     debug.print("--list = {}\n", .{});
    //
    // for (res.positionals) |pos|
    //     debug.print("{s}\n", .{pos});
}

// function to create a file ztore.db if it does not exist
fn createFile() !void {
    const db = try std.fs.cwd().createFile(
        "ztore.db",
        .{ .read = true },
    );
    defer db.close();
}

// function to add a new entry to the database
// https://github.com/ziglang/zig/issues/14375#issuecomment-1397306429
fn addEntry(item: []const u8) !void {
    const db = try std.fs.cwd().openFile("ztore.db", .{
        .mode = .read_write,
    });
    var stat = try db.stat();
    try db.seekTo(stat.size);

    defer db.close();

    try db.writer().writeAll("\n");
    try db.writer().writeAll(item);
}

// function to list the elements in the database
fn listEntries() !void {
    const db = try std.fs.cwd().openFile("ztore.db", .{});
    defer db.close();

    const reader = db.reader();
    var buf: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        std.debug.print("{s}\n ", .{line});
    }
}
