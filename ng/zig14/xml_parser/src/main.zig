const std = @import("std");

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
    data: []const u8,
    derivedFrom: []const u8,
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("We have memory leak\n", .{});
        } else {
            std.debug.print("No memory leak\n", .{});
        }
    }

    const allocator = gpa.allocator();
    // const ptr = try allocator.create(u8); // allocate single item
    const xmlbuf = try allocator.alloc(u8, 1024); // allocate array of items
    defer allocator.free(xmlbuf);

    const fileName = "test.xml";
    const state = SvdParseState.Device;
    _ = state;

    const xmlFile = try std.fs.cwd().openFile(fileName, .{ .mode = .read_only });
    defer xmlFile.close();

    const fileStats = xmlFile.stat();
    try std.io.getStdOut().writer().print("\nstats: {!}", .{fileStats});

    while (try xmlFile.reader().readUntilDelimiterOrEof(xmlbuf, '\n')) |line| {
        if (line.len == 0) {
            break;
        }
        const chunk = parseXmlLine(line) orelse continue;
        _ = chunk;
        try stdout.print("\n======================================\n", .{});
        // try stdout.print("\ntag: {s}", .{chunk.tag});
        // try stdout.print("\ndata: {s}", .{chunk.data});
        // try stdout.print("\nderivedFrom: {s}", .{chunk.derivedFrom});
    }

    try std.io.getStdOut().writer().print("\n==================\n", .{});
}

fn parseXmlLine(line: []const u8) ?XmlLine {
    var chunk = XmlLine{
        .tag = undefined,
        .data = undefined,
        .derivedFrom = undefined,
    };

    const trimmed = std.mem.trim(u8, line, " \n\r");
    var empty_tag = if (std.mem.count(u8, line, "></") > 0) true else false;
    var necked_xml_line = std.mem.tokenizeAny(u8, trimmed, "<>");

    var x = std.mem.tokenizeAny(u8, trimmed, "<>");
    myPrint(x.next().?);
    myPrint(x.next().?);
    myPrint(x.next().?);
    myPrint(x.next().?);
    // std.debug.print("\n 1: {c}", .{x.next()});
    // std.debug.print("\n 1: {any}", .{x.next()});
    // std.debug.print("\n 1: {any}", .{x.next()});
    // std.debug.print("\n 1: {any}", .{x.next()});

    if (necked_xml_line.next()) |tag_with_props| {
        var tag_or_prop = std.mem.tokenizeAny(u8, tag_with_props, "=\"");

        const tag = tag_or_prop.next() orelse return undefined;
        // std.debug.print("\n tag: {s}", .{tag});
        chunk.tag = tag;
        if (tag_or_prop.next()) |tag_property| {
            if (std.ascii.eqlIgnoreCase(tag_property, "derivedFrom")) {
                const derivedFrom_value = tag_or_prop.next().?;
                chunk.derivedFrom = derivedFrom_value;
            }
        }
    } else {
        return undefined;
    }
    if (necked_xml_line.next()) |value| {
        if (!empty_tag) {
            chunk.data = value;
        } else {
            chunk.data = undefined;
        }
    }
    empty_tag = false;
    return chunk;
}

fn myPrint(word: []const u8) void {
    for (word) |ch| {
        // try std.io.getStdOut().writer().print("{c}", .{ch});
        std.debug.print("{c}", .{ch});
    }
}

test "parseXmlLine" {
    const valid_xml = "  <description>STM32F411</description>  \n";
    const expected_chunk = XmlLine{ .tag = "description", .data = "STM32F411", .derivedFrom = undefined };
    const xml_line = parseXmlLine(valid_xml).?;
    try std.testing.expectEqualSlices(
        u8,
        expected_chunk.tag,
        xml_line.tag,
    );
}
