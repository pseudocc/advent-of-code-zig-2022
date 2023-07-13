const std = @import("std");

const input = struct {
    const example = @embedFile("example");
    const puzzle = @embedFile("puzzle");
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

const Move = struct {
    from: usize,
    to: usize,
    amount: usize,

    pub fn parse(line: []const u8) !Move {
        var black_hole: []const u8 = undefined;
        var parts = std.mem.tokenize(u8, line, " ");

        black_hole = parts.next() orelse return ParsingError.Unexpected;
        if (!std.mem.eql(u8, black_hole, "move")) {
            return ParsingError.Unexpected;
        }

        const amount_str = parts.next() orelse return ParsingError.Unexpected;
        const amount = try std.fmt.parseUnsigned(usize, amount_str, 0);

        black_hole = parts.next() orelse return ParsingError.Unexpected;
        if (!std.mem.eql(u8, black_hole, "from")) {
            return ParsingError.Unexpected;
        }

        const from_str = parts.next() orelse return ParsingError.Unexpected;
        const from = try std.fmt.parseUnsigned(usize, from_str, 0);

        black_hole = parts.next() orelse return ParsingError.Unexpected;
        if (!std.mem.eql(u8, black_hole, "to")) {
            return ParsingError.Unexpected;
        }

        const to_str = parts.next() orelse return ParsingError.Unexpected;
        const to = try std.fmt.parseUnsigned(usize, to_str, 0);

        return Move{
            .from = from,
            .to = to,
            .amount = amount,
        };
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

test "move parsing" {
    const expect = std.testing.expect;

    var move = try Move.parse("move 1 from 2 to 0");
    try expect(1 == move.amount);
    try expect(2 == move.from);
    try expect(0 == move.to);
}

fn one_crate(raw: []const u8, alloc: Allocator) ![]const u8 {
    var parts = std.mem.split(u8, raw, "\n\n");
    const cargo_part = parts.next().?;
    var cargo = try Cargo.parse(cargo_part, alloc);
    defer cargo.deinit();

    const moves_part = parts.next().?;
    var moves = std.mem.tokenize(u8, moves_part, "\n");

    const offset: usize = 1;
    while (moves.next()) |line| {
        const move = try Move.parse(line);
        var from = &cargo.stacks.items[move.from - offset];
        var to = &cargo.stacks.items[move.to - offset];

        for (0..move.amount) |_| {
            var next = from.*.?.next;
            from.*.?.next = to.*;
            to.* = from.*;
            from.* = next;
        }
    }

    var result = try alloc.alloc(u8, cargo.stacks.items.len);
    var pos: usize = 0;

    for (cargo.stacks.items) |node| {
        if (node == null) {
            continue;
        }
        result[pos] = node.?.data;
        pos += 1;
    }

    result = try alloc.realloc(result, pos);
    return result;
}

test "part 1" {
    const alloc = std.testing.allocator;
    const expect = std.testing.expect;

    var result = try one_crate(input.example, alloc);
    defer alloc.free(result);

    const expected = "CMZ";
    try expect(std.mem.eql(u8, result, expected));
}

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    const part1 = try one_crate(input.puzzle, alloc);
    defer alloc.free(part1);

    std.log.debug("part 1: {s}", .{part1});
}
