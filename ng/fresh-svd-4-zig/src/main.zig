const std = @import("std");
const svd = @import("svd.zig");

// // modifiable array
var line_buffer: [1024 * 1024]u8 = undefined;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const cwd = try std.fs.cwd().openIterableDir(".", .{});
    var iterator = cwd.iterate();
    while (try iterator.next()) |path| {
        try stdout.print("{s}\n", .{path.name});
    }

    const fileName = "hakuna.txt";
    const file = try std.fs.cwd().openFile(fileName, .{ .mode = .read_only });
    var buf_reader = std.io.bufferedReader(file.reader()); //this must be var
    const in_stream = buf_reader.reader();
    _ = in_stream;

    var buf: [20 * 1024]u8 = undefined;
    while (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var trimmed = std.mem.trim(u8, line, " \n");
        var toker = std.mem.tokenize(u8, trimmed, "<>"); //" =\n<>\"");
        try stdout.print("toker: {any}\n", .{toker});
        while (toker.next()) |something| {
            try stdout.print("something: {any}\n", .{something});
        }
    }

    // with argsAlloc the allocator is there specifically to allocate argv

    // ->> the argsWithAllocator doesn't use the allocator on every system, the argsAlloc allocates the args array on every system
    var args = try std.process.argsWithAllocator(allocator);

    while (args.next()) |arg| {
        try stdout.print("{s}\n", .{arg.ptr});
    }
}

const SvdParseState = enum {
    Device,
    Cpu,
    Peripherals,
    Peripheral,
    AddressBlock,
    Interrupt,
    Registers,
    Register,
    Fields,
    Field,
    Finished,
};

const XmlLine = struct {
    tag: []const u8,
    data: ?[]const u8,
    derivedFrom: ?[]const u8,
};

// getChunk
fn parseXmlLine(line: []const u8) ?XmlLine {
    _ = line;
    var diassembledLine = XmlLine{ .tag = undefined, .data = null, .derifedFrom = null };

    return diassembledLine;
}
