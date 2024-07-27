const std = @import("std");
const Allocator = std.mem.Allocator;

const List = struct {
    const Node = struct {
        data: u8,
        next: ?*Node,

        fn create(allocator: Allocator, data: u8) !*Node {
            // Here we don't use defer or errdefer because
            // no errors can occur after the allocation.
            var self = try allocator.create(Node);
            self.data = data;
            self.next = null;
            return self;
        }

        fn deinit(self: *Node, allocator: Allocator) void {
            if (self.next) |node_ptr| {
                node_ptr.deinit(allocator);
                allocator.destroy(node_ptr);
            }
        }
    };

    allocator: Allocator,
    head: *Node,
    tail: *Node,

    fn init(allocator: Allocator, data: u8) !List {
        // Once again, no errors can occur after the
        // allocation, son no defer or errdefer needed.
        var self = List{
            .allocator = allocator,
            .head = try Node.create(allocator, data),
            .tail = undefined,
        };
        self.tail = self.head;
        return self;
    }

    fn initListWithSlice(allocator: Allocator, slice: []const u8) !List {
        var self = try List.init(allocator, slice[0]);
        // Here we can't use defer because we want to return the
        // list on success. We only need to call `deinit` if an
        // error occurs, so errdefer is made just for that.
        errdefer self.deinit();

        for (slice[1..]) |data| try self.append(data);
        return self;
    }

    fn deinit(self: *List) void {
        self.head.deinit(self.allocator);
        self.allocator.destroy(self.head);
    }

    fn append(self: *List, data: u8) !void {
        self.tail.next = try Node.create(self.allocator, data);
        self.tail = self.tail.next.?;
    }

    fn contains(self: List, data: u8) bool {
        var current: ?*Node = self.head;

        return while (current) |node_ptr| {
            if (node_ptr.data == data) break true;
            current = node_ptr.next;
        } else false;
    }

    fn print(self: List) void {
        var current: ?*Node = self.head;
        var i: usize = 0;

        while (current) |node_ptr| : (i += 1) {
            std.debug.print("List[{}]: {}\n", .{ i, node_ptr.data });
            current = node_ptr.next;
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = try List.initListWithSlice(allocator, &.{ 13, 42, 33 });
    // Call deinit no matter how we exit main.
    defer list.deinit();

    try list.append(99);

    std.debug.print("found 42? {}\n", .{list.contains(42)});
    std.debug.print("found 99? {}\n", .{list.contains(99)});
    std.debug.print("found 100? {}\n", .{list.contains(100)});

    std.debug.print("\n", .{});
    list.print();
    std.debug.print("\n", .{});

    // Prints last.
    defer std.debug.print("defer 1\n", .{});
    // Prints first.
    defer std.debug.print("defer 2\n", .{});
    // Not called if never reached.
    if (false) {
        defer std.debug.print("defer 3\n", .{});
    }
    // Only on error return. You can capture the error.
    errdefer |err| std.debug.print("errdefer; error {}\n", .{err});

    // return error.Boom;
}
