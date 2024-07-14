const std = @import("std");

pub fn main() !void {
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

    const stdout = std.io.getStdOut().writer();
    const fileName = "hakuna.txt";

    const file = try std.fs.cwd().openFile(fileName, .{ .mode = .read_only });

    var buf: [2048]u8 = undefined;
    while (try file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try stdout.print("\nline: {any}", .{line});
        try stdout.print("\nline: {s}", .{line});
    }

    try stdout.print("======================================", .{});

    const testXmlName = "test.xml";
    const state = SvdParseState.Device;
    _ = state;
    const xmlFile = try std.fs.cwd().openFile(testXmlName, .{ .mode = .read_only });
    var xmlbuf: [20 * 1024]u8 = undefined;
    while (try xmlFile.reader().readUntilDelimiterOrEof(&xmlbuf, '\n')) |line| {
        if (line.len == 0) {
            break;
        }
        const chunk = parseXmlLine(line) orelse continue;
        try stdout.print("\n======================================\n", .{});
        try stdout.print("\ntag: {s}", .{chunk.tag});
        try stdout.print("\ndata: {s}", .{chunk.data});
        try stdout.print("\nderivedFrom: {s}", .{chunk.derivedFrom});
    }
}

const XmlLine = struct {
    tag: []const u8,
    data: []const u8,
    derivedFrom: []const u8,
};

// getChunk
fn parseXmlLine(line: []const u8) ?XmlLine {
    var chunk = XmlLine{
        .tag = undefined,
        .data = undefined,
        .derivedFrom = undefined,
    };

    const trimmed = std.mem.trim(u8, line, " \n\r");
    var empty_tag = if (std.mem.count(u8, line, "></") > 0) true else false;

    var necked_xml_line = std.mem.tokenize(u8, trimmed, "<>");

    if (necked_xml_line.next()) |tag_with_props| {
        var tag_or_prop = std.mem.tokenize(u8, tag_with_props, " =\"");
        const tag = tag_or_prop.next() orelse return undefined;
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
            // chunk.data = undefined;
        }
    }
    empty_tag = false;
    return chunk;
}

test "parseXmlLine" {
    const valid_xml = "  <name>STM32F7x7</name>  \n";
    const expected_chunk = XmlLine{ .tag = "name", .data = "STM32F7x7", .derivedFrom = undefined };

    const chunk = parseXmlLine(valid_xml).?;
    try std.testing.expectEqualSlices(u8, chunk.tag, expected_chunk.tag);
    try std.testing.expectEqualSlices(u8, chunk.data, expected_chunk.data);

    const no_data_xml = "  <name></name> \n";
    const expected_no_data_chunk = XmlLine{ .tag = "name", .data = undefined, .derivedFrom = undefined };
    const no_data_chunk = parseXmlLine(no_data_xml).?;
    try std.testing.expectEqualSlices(u8, no_data_chunk.tag, expected_no_data_chunk.tag);
    try std.testing.expectEqual(no_data_chunk.data, expected_no_data_chunk.data);

    // const comments_xml = "<description>Auxiliary Cache Control register</description>";
    // const derived = "   <peripheral derivedFrom=\"TIM10\">";
}
