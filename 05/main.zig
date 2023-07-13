const std = @import("std");

const input = struct {
    const example = @embedFile("example");
    const puzzle = @embedFile("example");
};

const Allocator = std.mem.Allocator;
const ListNode = struct {
    next: ?*ListNode = null,
    data: u8,

    pub fn invert(indirect: *?*ListNode) void {
        if (indirect.* == null) {
            return;
        }
        var current: *ListNode = indirect.*.?;
        while (current.next) |next| {
            current.next = next.next;
            next.next = indirect.*;
            indirect.* = next;
        }
    }
};

const ParsingError = error{Unexpected};
const Cargo = struct {
    stacks: std.ArrayList(?*ListNode),
    arena: std.heap.ArenaAllocator,

    pub fn parse(raw: []const u8, alloc: Allocator) !Cargo {
        var lines = std.mem.tokenize(u8, raw, "\n");
        const first = lines.peek() //
        orelse return ParsingError.Unexpected;

        var arena = std.heap.ArenaAllocator.init(alloc);
        const arena_alloc = arena.allocator();

        const n_stacks = (first.len + 1) / 4;
        var stacks = try std.ArrayList(?*ListNode).initCapacity(arena_alloc, n_stacks);
        stacks.appendNTimesAssumeCapacity(null, n_stacks);

        errdefer arena.deinit();

        while (lines.next()) |line| {
            for (0..n_stacks) |i| {
                var j = i << 2;
                const c = line[j];
                if (c == ' ') {
                    continue;
                }
                if (c != '[') {
                    return ParsingError.Unexpected;
                }

                if (line[j + 2] != ']') {
                    return ParsingError.Unexpected;
                }
                const data = line[j + 1];
                const head = stacks.items[i];
                var new_head_slice = try arena_alloc.alloc(ListNode, 1);
                var new_head = &new_head_slice[0];

                new_head.* = ListNode{ .next = head, .data = data };
                stacks.items[i] = new_head;
            }
        }

        for (0..n_stacks) |i| {
            ListNode.invert(&stacks.items[i]);
        }

        return Cargo{
            .stacks = stacks,
            .arena = arena,
        };
    }

    pub fn deinit(self: *Cargo) void {
        self.arena.deinit();
    }
};

test "list invert" {
    const expect = std.testing.expect;

    var node0 = ListNode{ .next = null, .data = 'A' };
    var node1 = ListNode{ .next = &node0, .data = 'B' };
    var node2 = ListNode{ .next = &node1, .data = 'C' };

    var head: ?*ListNode = &node2;
    ListNode.invert(&head);

    try expect('A' == head.?.data);
    try expect('B' == head.?.next.?.data);
    try expect('C' == head.?.next.?.next.?.data);
}

test "cargo parsing" {
    const alloc = std.testing.allocator;
    const expect = std.testing.expect;

    var parts = std.mem.split(u8, input.example, "\n\n");
    const cargo_part = parts.next().?;
    var cargo = try Cargo.parse(cargo_part, alloc);
    defer cargo.deinit();

    try expect(3 == cargo.stacks.items.len);

    const stack0 = cargo.stacks.items[0];
    try expect('N' == stack0.?.data);
    try expect('Z' == stack0.?.next.?.data);
    try expect(null == stack0.?.next.?.next);
}
