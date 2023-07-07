const std = @import("std");

const input = struct {
    const example = @embedFile("example");
    const puzzle = @embedFile("puzzle");
};

/// A max heap that only keeps track of the top 3 values.
/// I am just too lazy to implement a proper max heap.
fn PatheticMaxHeap(comptime T: type) type {
    return struct {
        first: T,
        second: T,
        third: T,

        const Self = @This();

        pub fn add(self: *Self, value: T) void {
            if (value > self.first) {
                self.third = self.second;
                self.second = self.first;
                self.first = value;
            } else if (value > self.second) {
                self.third = self.second;
                self.second = value;
            } else if (value > self.third) {
                self.third = value;
            }
        }

        pub fn total(self: *Self) T {
            std.log.debug("{}\n", .{self});
            return self.first + self.second + self.third;
        }
    };
}

const IntegerIterator = struct {
    lines: std.mem.SplitIterator(u8),

    fn Result(comptime T: type) type {
        return struct {
            done: bool,
            value: T,
        };
    }

    pub fn new(raw: []const u8) IntegerIterator {
        const lines = std.mem.split(u8, raw, "\n");
        return IntegerIterator{ .lines = lines };
    }

    pub fn next(self: *IntegerIterator, comptime T: type) !Result(?T) {
        const line = self.lines.next() orelse return .{ .done = true, .value = undefined };
        if (line.len == 0) return .{ .done = false, .value = null };
        const value = try std.fmt.parseInt(T, line, 10);
        return .{ .done = false, .value = value };
    }
};

fn calorie_counting_p1(entry: []const u8) !u32 {
    var iter = IntegerIterator.new(entry);

    var total: u32 = 0;
    var max_sf: u32 = 0;

    while (true) {
        const it = try iter.next(u32);
        if (it.done) break;
        if (it.value == null) {
            if (total > max_sf) max_sf = total;
            total = 0;
        } else {
            total += it.value.?;
        }
    }

    if (total > max_sf) max_sf = total;
    return max_sf;
}

fn calorie_counting_p2(entry: []const u8) !u32 {
    var iter = IntegerIterator.new(entry);

    var max_heap = PatheticMaxHeap(u32){
        .first = 0,
        .second = 0,
        .third = 0,
    };
    var total: u32 = 0;

    while (true) {
        const it = try iter.next(u32);
        if (it.done) break;
        if (it.value == null) {
            max_heap.add(total);
            total = 0;
        } else {
            total += it.value.?;
        }
    }

    max_heap.add(total);
    return max_heap.total();
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var answer: u32 = undefined;

    answer = try calorie_counting_p1(input.puzzle);
    try stdout.print("P1: {d}\n", .{answer});

    answer = try calorie_counting_p2(input.puzzle);
    try stdout.print("P2: {d}\n", .{answer});
}

test "calorie counting" {
    const expected_p1: u32 = 24000;
    const actual_p1 = try calorie_counting_p1(input.example);
    try std.testing.expectEqual(expected_p1, actual_p1);

    const expected_p2: u32 = 45000;
    const actual_p2 = try calorie_counting_p2(input.example);
    try std.testing.expectEqual(expected_p2, actual_p2);
}

test "line iterator" {
    var iter = IntegerIterator.new(input.example);

    const expected_list = [_]?u32{
        1000, 2000,  3000, null,
        4000, null,  5000, 6000,
        null, 7000,  8000, 9000,
        null, 10000, null,
    };

    for (expected_list) |expected| {
        const actual = try iter.next(u32);
        try std.testing.expectEqual(false, actual.done);
        try std.testing.expectEqual(expected, actual.value);
    }

    const actual = try iter.next(u32);
    try std.testing.expectEqual(true, actual.done);
}
