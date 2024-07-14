const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    _ = stdout;
    const testXmlName = "test.xml";

    const xmlFile = try std.fs.cwd().openFile(testXmlName, .{ .mode = .read_only });
    var xmlbuf: [20 * 1024]u8 = undefined;
    while (try xmlFile.reader().readUntilDelimiterOrEof(&xmlbuf, '\n')) |line| {
        try std.io.getStdOut().writer().print("\n trimmed_line: {s}", .{line});

        if (line.len == 0) {
            break;
        }
        try parseXmlLine(line);
    }
}

fn parseXmlLine(line: []const u8) !void {
    const trimmed = std.mem.trim(u8, line, " \n\r");

    const empty_tag = std.mem.count(u8, line, "></");
    try std.io.getStdOut().writer().print("\n empty_tag: {any}", .{empty_tag});
    var toker = std.mem.tokenize(u8, trimmed, "<>");
    while (toker.next()) |xml_Line| {
        try std.io.getStdOut().writer().print("\n xml_Line: {s}", .{xml_Line});

        var tag_toker = std.mem.tokenize(u8, xml_Line, " =\"");
        while (tag_toker.next()) |tag| {
            try std.io.getStdOut().writer().print("\n tag: {s}", .{tag});
        }
    }
}

// $ zig build run
// steps [4/7] install...
//  trimmed_line: <?xml version="1.0" encoding="utf-8" standalone="no"?>
//  xml_Line: ?xml version="1.0" encoding="utf-8" standalone="no"?
//  tag: ?xml
//  tag: version
//  tag: 1.0
//  tag: encoding
//  tag: utf-8
//  tag: standalone
//  tag: no
//  tag: ?
//  trimmed_line: <device schemaVersion="1.1" xmlns:xs="http://www.w3.org/2001/XMLSchema-instance" xs:noNamespaceSchemaLocation="CMSIS-SVD_Schema_1_1.xsd">
//  xml_Line: device schemaVersion="1.1" xmlns:xs="http://www.w3.org/2001/XMLSchema-instance" xs:noNamespaceSchemaLocation="CMSIS-SVD_Schema_1_1.xsd"
//  tag: device
//  tag: schemaVersion
//  tag: 1.1
//  tag: xmlns:xs
//  tag: http://www.w3.org/2001/XMLSchema-instance
//  tag: xs:noNamespaceSchemaLocation
//  tag: CMSIS-SVD_Schema_1_1.xsd
//  trimmed_line:   <name>STM32F411</name>
//  xml_Line: name
//  tag: name
//  xml_Line: STM32F411
//  tag: STM32F411
//  xml_Line: /name
//  tag: /name
//  trimmed_line:   <version>1.1</version>
//  xml_Line: version
//  tag: version
//  xml_Line: 1.1
//  tag: 1.1
//  xml_Line: /version
//  tag: /version
//  trimmed_line:   <description>STM32F411</description>
//  xml_Line: description
//  tag: description
//  xml_Line: STM32F411
//  tag: STM32F411
//  xml_Line: /description
//  tag: /description
//  trimmed_line:   <peripheral derivedFrom="TIM3">
//  xml_Line: peripheral derivedFrom="TIM3"
//  tag: peripheral
//  tag: derivedFrom
//  tag: TIM3
//  trimmed_line:       <name>TIM4</name>
//  xml_Line: name
//  tag: name
//  xml_Line: TIM4
//  tag: TIM4
//  xml_Line: /name
//  tag: /name
//  trimmed_line:       <baseAddress>0x40000800</baseAddress>
//  xml_Line: baseAddress
//  tag: baseAddress
//  xml_Line: 0x40000800
//  tag: 0x40000800
//  xml_Line: /baseAddress
//  tag: /baseAddress
//  trimmed_line:   </peripheral>
//  xml_Line: /peripheral
//  tag: /peripheral
//  trimmed_line: </device>
//  xml_Line: /device

test "String contains" {
    const message = "<resetValue></resetValue>";
    var contains = if (std.mem.count(u8, message, "><") > 0) true else false;
    try std.testing.expect(contains);

    contains = if (std.mem.count(u8, message, "What") > 0) true else false;
    try std.testing.expect(!contains);
}
