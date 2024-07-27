const std = @import("std");

// Memory Sections or Where are the bytes?

// Stored in global constant section of memory.
const pi: f64 = 3.1415;
const greeting = "Hello";

// Stored in the global data section.
var count: usize = 0;

fn locals() u8 {
    // All of these local variables are gone
    // once the function exits. They live on the
    // function's stack frame.
    const a: u8 = 1;
    const b: u8 = 2;
    const result: u8 = a + b;
    // Here a copy of result is returned,
    // since it's a primitive numeric type.
    return result;
}

fn badIdea1() *u8 {
    // `x` lives on the stack.
    var x: u8 = 42;
    // Invalid pointer once the function returns
    // and its stack frame is destroyed.
    return &x;
}

fn badIdea2() []u8 {
    var array: [5]u8 = .{ 'H', 'e', 'l', 'l', 'o' };
    // Remember, a slice is also a pointer!
    const s = array[2..];
    // This is an error since `array` will be destroyed
    // when the function returns. `s` will be left dangling.
    return s;
}

// Caller must free returned bytes.
fn goodIdea(allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
    var array: [5]u8 = .{ 'H', 'e', 'l', 'l', 'o' };
    // `s` is a []u8 with length 5 and a pointer to bytes on the heap.
    const s = try allocator.alloc(u8, 5);
    std.mem.copy(u8, s, &array);
    // This is OK since `s` points to bytes allocated on the
    // heap and thus outlives the function's stack frame.
    return s;
}

const Foo = struct {
    s: []u8,

    // When a type needs to initialized resources, such as allocating
    // memory, it's convention to do it in a `init` method.
    fn init(allocator: std.mem.Allocator, s: []const u8) !*Foo {
        // `create` allocates space on the heap for a single value.
        // It returns a pointer.
        const foo_ptr = try allocator.create(Foo);
        errdefer allocator.destroy(foo_ptr);
        // `alloc` allocates space on the heap for many values.
        // It returns a slice.
        foo_ptr.s = try allocator.alloc(u8, s.len);
        std.mem.copy(u8, foo_ptr.s, s);
        // Or: foo_ptr.s = try allocator.dupe(s);

        return foo_ptr;
    }

    // When a type needs to clean-up resources, it's convention
    // to do it in a `deinit` method.
    fn deinit(self: *Foo, allocator: std.mem.Allocator) void {
        // `free` works on slices allocated with `alloc`.
        allocator.free(self.s);
        // `destroy` works on pointers allocated with `create`.
        allocator.destroy(self);
    }
};

test Foo {
    const allocator = std.testing.allocator;
    var foo_ptr = try Foo.init(allocator, greeting);
    defer foo_ptr.deinit(allocator);

    try std.testing.expectEqualStrings(greeting, foo_ptr.s);
}

pub fn main() !void {}

// Take an output variable, returning number of bytes written into it.
fn catOutVarLen(
    a: []const u8,
    b: []const u8,
    out: []u8,
) usize {
    // Make sure we have enough space.
    std.debug.assert(out.len >= a.len + b.len);
    // Copy the bytes.
    std.mem.copy(u8, out, a);
    std.mem.copy(u8, out[a.len..], b);
    // Return the number of bytes copied.
    return a.len + b.len;
}

test "catOutVarLen" {
    const hello: []const u8 = "Hello ";
    const world: []const u8 = "world";

    // Our output buffer.
    var buf: [128]u8 = undefined;

    // Write to buffer, get length.
    const len = catOutVarLen(hello, world, &buf);
    try std.testing.expectEqualStrings(hello ++ world, buf[0..len]);
    // If you're feeling clever, you can also do this.
    try std.testing.expectEqualStrings(hello ++ world, buf[0..catOutVarLen(hello, world, &buf)]);
}

// Take an output variable returning a slice from it.
fn catOutVarSlice(
    a: []const u8,
    b: []const u8,
    out: []u8,
) []u8 {
    // Make sure we have enough space.
    std.debug.assert(out.len >= a.len + b.len);
    // Copy the bytes.
    std.mem.copy(u8, out, a);
    std.mem.copy(u8, out[a.len..], b);
    // Return the slice of copied bytes.
    return out[0 .. a.len + b.len];
}

test "catOutVarSlice" {
    const hello: []const u8 = "Hello ";
    const world: []const u8 = "world";

    // Our output buffer.
    var buf: [128]u8 = undefined;

    // Write to buffer get slice.
    const slice = catOutVarSlice(hello, world, &buf);
    try std.testing.expectEqualStrings(hello ++ world, slice);
}

// Take an allocator, return bytes allocated with it. Caller must free returned bytes.
fn catAlloc(
    allocator: std.mem.Allocator,
    a: []const u8,
    b: []const u8,
) ![]u8 {
    // Try to allocate enough space. Returns a []T on success.
    const bytes = try allocator.alloc(u8, a.len + b.len);
    // Copy the bytes.
    std.mem.copy(u8, bytes, a);
    std.mem.copy(u8, bytes[a.len..], b);
    // Return the allocated slice.
    return bytes;
}

test "catAlloc" {
    const hello: []const u8 = "Hello ";
    const world: []const u8 = "world";
    const allocator = std.testing.allocator;

    // Write to buffer get slice.
    const slice = try catAlloc(allocator, hello, world);
    defer allocator.free(slice);
    try std.testing.expectEqualStrings(hello ++ world, slice);
}

// Always fails; just to demonstrate errdefer.
fn mayFail() !void {
    return error.Boom;
}
