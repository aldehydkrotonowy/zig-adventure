const std = @import("std");
const helper = @import("helper.zig");

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
    const xmlbuf = try allocator.alloc(u8, 4 * 1024); // allocate array of items
    defer allocator.free(xmlbuf);

    const fileName = "test.xml";
    const state = SvdParseState.Device;
    _ = state;

    const xmlFile = try std.fs.cwd().openFile(fileName, .{ .mode = .read_only });
    defer xmlFile.close();

    // const fileStats = xmlFile.stat();
    // try std.io.getStdOut().writer().print("\nstats: {!}", .{fileStats});

    while (try xmlFile.reader().readUntilDelimiterOrEof(xmlbuf, '\n')) |line| {
        if (line.len == 0) {
            break;
        }
        const chunk = parseXmlLine(line) orelse continue;
        try stdout.print("\n chunk ======================================\n", .{});
        helper.printSlice("tag: ", chunk.tag);
        helper.printSlice("data: ", chunk.data);
        helper.printSlice("derivedFrom: ", chunk.derivedFrom);
    }

    // try std.io.getStdOut().writer().print("\n==================\n", .{});
}

fn parseXmlLine(line: []const u8) ?XmlLine {
    var chunk = XmlLine{
        .tag = undefined,
        .data = null,
        .derivedFrom = null,
    };

    const trimmed = std.mem.trim(u8, line, " \n\r");
    var empty_tag = if (std.mem.count(u8, line, "></") > 0) true else false;
    var necked_xml_line = std.mem.tokenizeAny(u8, trimmed, "<>");

    if (necked_xml_line.next()) |tag_with_maby_props| {
        if (std.mem.containsAtLeast(u8, tag_with_maby_props, 1, "=\"")) {
            var tag_and_prop_it = std.mem.tokenizeAny(u8, tag_with_maby_props, " =\"");
            const just_tag = tag_and_prop_it.next().?;
            _ = tag_and_prop_it.next(); //omit derivedFrom prop;
            const derivedFrom_value = tag_and_prop_it.next().?;
            chunk.tag = just_tag;
            chunk.derivedFrom = derivedFrom_value;
        } else {
            const just_tag = tag_with_maby_props;
            chunk.tag = just_tag;
        }
    } else {
        return null;
    }
    if (necked_xml_line.next()) |value| {
        if (!empty_tag) {
            chunk.data = value;
        } else {
            chunk.data = null;
        }
    }
    empty_tag = false;
    return chunk;
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
    try std.testing.expectEqualSlices(u8, expected_chunk.data.?, xml_line.data.?);

    const no_data_xml = "  <name> \n";
    const expected_no_data_chunk = XmlLine{ .tag = "name", .data = null, .derivedFrom = null };
    const no_data_chunk = parseXmlLine(no_data_xml).?;
    try std.testing.expectEqualSlices(u8, expected_no_data_chunk.tag, no_data_chunk.tag);
    try std.testing.expectEqual(expected_no_data_chunk.data, no_data_chunk.data);

    const end_data_xml = "</device>\n";
    const expected_end_data_chunk = XmlLine{ .tag = "/device", .data = null, .derivedFrom = null };
    const end_data_chunk = parseXmlLine(end_data_xml).?;
    try std.testing.expectEqualSlices(u8, expected_end_data_chunk.tag, end_data_chunk.tag);
    try std.testing.expectEqual(expected_end_data_chunk.data, end_data_chunk.data);

    const comments_xml = "<description>Auxiliary Cache Control register</description>";
    const expected_comments_chunk = XmlLine{ .tag = "description", .data = "Auxiliary Cache Control register", .derivedFrom = null };
    const comments_chunk = parseXmlLine(comments_xml).?;
    try std.testing.expectEqualSlices(u8, expected_comments_chunk.tag, comments_chunk.tag);
    try std.testing.expectEqualSlices(u8, expected_comments_chunk.data.?, comments_chunk.data.?);

    const derived = "   <peripheral derivedFrom=\"TIM10\">";
    const expected_derived_chunk = XmlLine{ .tag = "peripheral", .data = null, .derivedFrom = "TIM10" };
    const derived_chunk = parseXmlLine(derived).?;
    try std.testing.expectEqualSlices(u8, expected_derived_chunk.tag, derived_chunk.tag);
    try std.testing.expectEqual(expected_derived_chunk.data, derived_chunk.data);
    try std.testing.expectEqualSlices(u8, expected_derived_chunk.derivedFrom.?, derived_chunk.derivedFrom.?);
}
