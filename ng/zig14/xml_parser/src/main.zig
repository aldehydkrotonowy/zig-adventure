const std = @import("std");

pub fn main() !void {
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
    const bytes = try allocator.alloc(u8, 500); // allocate array of items
    defer allocator.free(bytes);

    const fileName = "hakuna.txt";

    const file = try std.fs.cwd().openFile(fileName, .{ .mode = .read_only });
    defer file.close();
    const stat = file.stat();
    try std.io.getStdOut().writer().print("\nstats: {!}", .{stat});

    while (try file.reader().readUntilDelimiterOrEof(bytes, '\n')) |line| {
        try std.io.getStdOut().writer().print("\nline: {any}", .{line});
        try std.io.getStdOut().writer().print("\nline: {s}", .{line});
    }

    try std.io.getStdOut().writer().print("\n==================\n", .{});
}
