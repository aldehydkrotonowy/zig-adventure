const std = @import("std");
const helper = @import("helper.zig");

const XMLParseError = error{invalidXML};

const Device = struct {
    name: std.ArrayList(u8),
    version: std.ArrayList(u8),
    description: std.ArrayList(u8),
    cpu: Cpu,
    /// Bus Interface Properties
    /// Smallest addressable unit in bits
    address_unit_bits: ?u32,
    /// the maximum data bit width accessible within a single transfer
    max_bit_width: ?u32,
    /// Start register default properties
    reg_default_size: ?u32,
    reg_default_reset_value: ?u32,
    reg_default_reset_mask: ?u32,
    peripherals: Peripherals,
    interrupts: Interrupts,

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator) !Self {
        const name = std.ArrayList(u8).init(allocator);
        return Self{ .name = name };
    }
};

const Cpu = struct {
    name: std.ArrayList(u8),
    revision: std.ArrayList(u8),
    endian: std.ArrayList(u8),
    mpu_present: ?bool,
    fpu_present: ?bool,
    nvic_prio_bits: ?u32,
    vendor_systick_config: ?bool,

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator) !Self {
        const name = std.ArrayList(u8).init(allocator);
        return Self{ .name = name };
    }
};

const Peripherals = std.ArrayList(Peripheral);
const Peripheral = struct {
    name: std.ArrayList(u8),
    group_name: std.ArrayList(u8),
    description: std.ArrayList(u8),
    base_address: ?u32,
    // address_block: ?AddressBlock,
    // registers: Registers,
    const Self = @This();
    pub fn init(allocator: std.mem.Allocator) !Self {
        const name = std.ArrayList(u8).init(allocator);
        errdefer name.deinit();
        const group_name = std.ArrayList(u8).init(allocator);
        errdefer group_name.deinit();
        const description = std.ArrayList(u8).init(allocator);
        errdefer description.deinit();

        return Self{
            .name = name,
            .group_name = group_name,
            .description = description,
            .base_address = null,
        };
    }
};

const Interrupts = std.AutoHashMap(u32, Interrupt);
const Interrupt = struct {};

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

pub fn main() XMLParseError!void {
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
    const device = try Device.init(allocator);

    const xmlFile = try std.fs.cwd().openFile(fileName, .{ .mode = .read_only });
    defer xmlFile.close();

    // const fileStats = xmlFile.stat();
    // try std.io.getStdOut().writer().print("\nstats: {!}", .{fileStats});

    while (try xmlFile.reader().readUntilDelimiterOrEof(xmlbuf, '\n')) |line| {
        if (line.len == 0) {
            break;
        }
        const chunk = parseXmlLine(line) orelse continue;
        // try stdout.print("\n chunk ======================================\n", .{});
        // helper.printSlice("tag: ", chunk.tag);
        // helper.printSlice("data: ", chunk.data);
        // helper.printSlice("derivedFrom: ", chunk.derivedFrom);

        switch (state) {
            .Device => {
                if (std.ascii.eqlIgnoreCase(chunk.tag, "/device")) {
                    state = .Finished;
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "name")) {
                    if (chunk.data) |data| {
                        try device.name.insertSlice(0, data);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "version")) {
                    if (chunk.data) |data| {
                        try device.version.insertSlice(0, data);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "description")) {
                    if (chunk.data) |data| {
                        try device.description.insertSlice(0, data);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "cpu")) {
                    const cpu = try Cpu.init(allocator);
                    device.cpu = cpu;
                    state = .Cpu;
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "addressUnitBits")) {
                    if (chunk.data) |data| {
                        device.address_unit_bits = std.fmt.parseInt(u32, data, 10);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "width")) {
                    if (chunk.data) |data| {
                        device.max_bit_width = std.fmt.parseInt(u32, data, 10);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "size")) {
                    if (chunk.data) |data| {
                        device.reg_default_size = std.fmt.parseInt(u32, data, 10);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "resetValue")) {
                    if (chunk.data) |data| {
                        device.reg_default_reset_value = std.fmt.parseInt(u32, data, 10);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "resetMask")) {
                    if (chunk.data) |data| {
                        device.reg_default_reset_mask = std.fmt.parseInt(u32, data, 10);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "peripherals")) {
                    state = .Peripherals;
                }
            },
            .Cpu => {
                if (std.ascii.eqlIgnoreCase(chunk.tag, "/cpu")) {
                    state = .Device;
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "name")) {
                    if (chunk.data) |data| {
                        try device.cpu.?.name.insertSlice(0, data);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "revision")) {
                    if (chunk.data) |data| {
                        try device.cpu.?.revision.insertSlice(0, data);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "endian")) {
                    if (chunk.data) |data| {
                        try device.cpu.?.endian.insertSlice(0, data);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "mpuPresent")) {
                    if (chunk.data) |data| {
                        device.cpu.?.mpu_present = helper.textToBool(data);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "fpuPresent")) {
                    if (chunk.data) |data| {
                        device.cpu.?.fpu_present = helper.textToBool(data);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "nvicPrioBits")) {
                    if (chunk.data) |data| {
                        device.cpu.?.nvic_prio_bits = std.fmt.parseInt(u32, data, 10);
                    }
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "vendorSystickConfig")) {
                    if (chunk.data) |data| {
                        device.cpu.?.vendor_systick_config = helper.textToBool(data);
                    }
                }
            },
            .Peripherals => {
                if (std.ascii.eqlIgnoreCase(chunk.tab, "/peripherals")) {
                    state = .Device;
                } else if (std.ascii.eqlIgnoreCase(chunk.tag, "peripheral")) {
                    const peripheral = try Peripheral.init(allocator);
                    try device.peripherals.append(peripheral);
                    state = .Peripheral;
                    if (chunk.derivedFrom) |derivedFrom| {
                        for (device.peripherals.items) |currentPeripheral| {
                            if (std.mem.eql(u8, currentPeripheral, derivedFrom)) {
                                try device.peripherals.append(try currentPeripheral.copy(allocator));
                                break;
                            }
                        }
                    }
                }
            },
            .Peripheral => {
                if (std.ascii.eqlIgnoreCase(chunk.tag, "/peripheral")) {
                    // state = .Peripherals;
                    state = .Finished;
                }
            },
            .AddressBlock => {},
            .Interrupt => {},
            .Registers => {},
            .Register => {},
            .Fields => {},
            .Field => {},
            .Finished => {},
        }
    }

    if (state == .Finished) {
        try std.io.getStdOut().writer().print("{}\n", .{device});
    } else {
        return XMLParseError.invalidXML;
    }
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
            var tag_and_prop_iter = std.mem.tokenizeAny(u8, tag_with_maby_props, " =\"");
            const just_tag = tag_and_prop_iter.next().?;
            _ = tag_and_prop_iter.next(); //omit derivedFrom prop;
            const derivedFrom_value = tag_and_prop_iter.next().?;
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
