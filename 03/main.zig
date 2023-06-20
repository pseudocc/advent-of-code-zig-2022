const std = @import("std");

const RucksackError = error{
    NotFound,
    NotEven,
    OutOfBounds,
};

fn priority(c: u8) !u8 {
    return switch (c) {
        'a'...'z' => c - 'a' + 1,
        'A'...'Z' => c - 'A' + 27,
        else => RucksackError.OutOfBounds,
    };
}

const SharedOverload = enum {
    Type,
    Priority,
};

fn shared(
    comptime overload: SharedOverload,
    left: []const u8,
    right: []const u8,
) RucksackError!u8 {
    const ht_size = (26 << 1) + 1;
    const ht_type = u8;

    var ht: [ht_size]ht_type = [1]ht_type{0} ** ht_size;

    for (left) |c| {
        const p = try priority(c);
        ht[p] += 1;
    }

    for (right) |c| {
        const p = try priority(c);
        if (ht[p] != 0) {
            return switch (overload) {
                .Type => c,
                .Priority => p,
            };
        }
    }

    return RucksackError.NotFound;
}

test "priority" {
    const expect = std.testing.expectEqual;
    const expectError = std.testing.expectError;

    try expect(1, comptime try priority('a'));
    try expect(26, comptime try priority('z'));
    try expect(27, comptime try priority('A'));
    try expect(52, comptime try priority('Z'));
    try expectError(RucksackError.OutOfBounds, comptime priority('0'));
}

test "priority sum" {
    const expect = std.testing.expect;
    const rucksacks = [_][]const u8{
        "vJrwpWtwJgWrhcsFMMfFFhFp",
        "jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL",
        "PmmdzqPrVvPwwTWBwg",
        "wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn",
        "ttgJtRGJQctTZtZT",
        "CrZsJsPPZsGzwwsLwLmpwMDw",
    };

    var sum: u32 = 0;
    for (rucksacks) |rucksack| {
        const left = rucksack[0 .. rucksack.len / 2];
        const right = rucksack[rucksack.len / 2 ..];
        const value: u8 = try shared(.Priority, left, right);
        sum += @as(u32, value);
    }
    try expect(sum == 157);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const input = try std.fs.cwd().openFile("input", .{ .mode = .read_only });

    const reader = input.reader();
    defer input.close();

    var buffer: [1024]u8 = undefined;
    var sum: u32 = 0;
    while (true) {
        const line = try reader.readUntilDelimiterOrEof(&buffer, '\n') orelse break;

        const left = line[0 .. line.len / 2];
        const right = line[line.len / 2 ..];
        const value: u8 = try shared(.Priority, left, right);
        sum += @as(u32, value);
    }

    try stdout.print("P1 sum: {}\n", .{sum});
}
