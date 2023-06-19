const std = @import("std");

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
    buffer: [1024]u8 = undefined,
    reader: std.fs.File.Reader,

    fn Result(comptime T: type) type {
        return struct {
            done: bool,
            value: T,
        };
    }

    pub fn new(file: std.fs.File) IntegerIterator {
        const reader = file.reader();
        return IntegerIterator{ .reader = reader };
    }

    pub fn next(self: *IntegerIterator, comptime T: type) !Result(?T) {
        const line = try self.reader.readUntilDelimiterOrEof(&self.buffer, '\n') //
        orelse return .{ .done = true, .value = undefined };
        if (line.len == 0) return .{ .done = false, .value = null };
        const value = try std.fmt.parseInt(T, line, 10);
        return .{ .done = false, .value = value };
    }
};

fn calorie_counting_p1(entry: []const u8) !u32 {
    const cwd = std.fs.cwd();
    const file = try cwd.openFile(entry, .{ .mode = .read_only });

    var iter = IntegerIterator.new(file);
    defer iter.reader.context.close();

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
    const cwd = std.fs.cwd();
    const file = try cwd.openFile(entry, .{ .mode = .read_only });

    var iter = IntegerIterator.new(file);
    defer iter.reader.context.close();

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

    answer = try calorie_counting_p1("input");
    try stdout.print("P1: {d}\n", .{answer});

    answer = try calorie_counting_p2("input");
    try stdout.print("P2: {d}\n", .{answer});
}

test "calorie counting" {
    const expected_p1: u32 = 24000;
    const actual_p1 = try calorie_counting_p1("test");
    try std.testing.expectEqual(expected_p1, actual_p1);

    const expected_p2: u32 = 45000;
    const actual_p2 = try calorie_counting_p2("test");
    try std.testing.expectEqual(expected_p2, actual_p2);
}

test "line iterator" {
    const cwd = std.fs.cwd();
    const file = try cwd.openFile("test", .{ .mode = .read_only });

    var iter = IntegerIterator.new(file);
    defer iter.reader.context.close();

    const expected_list = [_]?u32{
        1000, 2000,  3000, null,
        4000, null,  5000, 6000,
        null, 7000,  8000, 9000,
        null, 10000,
    };

    for (expected_list) |expected| {
        const actual = try iter.next(u32);
        try std.testing.expectEqual(false, actual.done);
        try std.testing.expectEqual(expected, actual.value);
    }

    const actual = try iter.next(u32);
    try std.testing.expectEqual(true, actual.done);
}
