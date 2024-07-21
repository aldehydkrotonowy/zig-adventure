const std = @import("std");

pub fn printSlice(text: ?[]const u8, word: ?[]const u8) void {
    if (text) |t| {
        std.debug.print("{s}", .{t});
    }

    if (word) |w| {
        for (w) |ch| {
            std.debug.print("{c}", .{ch});
        }
    } else {
        std.debug.print("{s}", .{"NULL"});
    }
    std.debug.print("{s}", .{" | "});
}
