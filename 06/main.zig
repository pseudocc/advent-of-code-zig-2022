const std = @import("std");

const input = struct {
    const example = @embedFile("example");
    const puzzle = @embedFile("puzzle");
};

const Node = struct {
    next: ?*Node = null,
};

const UniqMark = struct {
    head: ?*Node = null,
    tail: *?*Node = undefined,
    alphabet: [26]Node = [_]Node{Node{}} ** 26,
    length: usize = 0,

    const Self = @This();

    pub fn new() Self {
        var self = Self{};
        self.tail = &self.head;
        return self;
    }

    pub fn push(self: *Self, c: u8) usize {
        var node: *Node = &self.alphabet[c - 'a'];
        const node_next = &node.next;
        self.length += 1;

        if ((node_next.* != null) or (node_next == self.tail)) {
            const end = node_next.*;
            while (self.head != end) : (self.length -= 1) {
                const next = self.head.?.next;
                self.head.?.next = null;
                self.head = next;
            }
        }

        if (self.head == null) {
            self.tail = &self.head;
        }

        self.tail.* = node;
        self.tail = &node.next;
        return self.length;
    }
};

fn first_marker(data_stream: []const u8) usize {
    const target: usize = 4;
    var mark = UniqMark.new();
    var position: usize = 0;

    for (data_stream) |c| {
        position += 1;
        const length = mark.push(c);
        if (length == target) {
            break;
        }
    }

    return position;
}

pub fn main() !void {
    const position = first_marker(input.puzzle);
    std.log.debug("P1 first marker position: {}\n", .{position});
}

test "first_marker" {
    const expected: usize = 7;
    const actual: usize = first_marker(input.example);

    try std.testing.expectEqual(expected, actual);
}
