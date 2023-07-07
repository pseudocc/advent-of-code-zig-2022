const std = @import("std");

const input = struct {
    const example = @embedFile("example");
    const puzzle = @embedFile("puzzle");
};

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

fn common(
    comptime overload: SharedOverload,
    first: []const u8,
    second: []const u8,
    third: []const u8,
) RucksackError!u8 {
    const ht_size = (26 << 1) + 1;
    const ht_type = u8;

    var ht: [ht_size]ht_type = [1]ht_type{0} ** ht_size;

    for (first) |c| {
        const p = try priority(c);
        ht[p] = 1;
    }

    for (second) |c| {
        const p = try priority(c);
        if (ht[p] == 1) {
            ht[p] = 2;
        }
    }

    for (third) |c| {
        const p = try priority(c);
        if (ht[p] == 2) {
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
    var rucksacks = std.mem.tokenize(u8, input.example, "\n");
    var sum: u32 = undefined;

    sum = 0;
    while (rucksacks.next()) |rucksack| {
        const left = rucksack[0 .. rucksack.len / 2];
        const right = rucksack[rucksack.len / 2 ..];
        const value: u8 = try shared(.Priority, left, right);
        sum += @as(u32, value);
    }
    try expect(sum == 157);

    sum = 0;
    rucksacks.reset();
    inline for (0..2) |_| {
        const first = rucksacks.next().?;
        const second = rucksacks.next().?;
        const third = rucksacks.next().?;

        const value: u8 = try common(.Priority, first, second, third);
        sum += @as(u32, value);
    }
    try expect(sum == 70);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var rucksacks = std.mem.tokenize(u8, input.puzzle, "\n");
    var sum: u32 = undefined;
    var n_rucksacks: u32 = 0;

    sum = 0;
    while (rucksacks.next()) |rucksack| {
        const left = rucksack[0 .. rucksack.len / 2];
        const right = rucksack[rucksack.len / 2 ..];

        const value: u8 = try shared(.Priority, left, right);
        sum += @as(u32, value);
        n_rucksacks += 1;
    }

    try stdout.print("P1 sum: {}\n", .{sum});

    sum = 0;
    rucksacks.reset();
    for (0..n_rucksacks / 3) |_| {
        const first = rucksacks.next().?;
        const second = rucksacks.next().?;
        const third = rucksacks.next().?;

        const value: u8 = try common(.Priority, first, second, third);
        sum += @as(u32, value);
    }

    try stdout.print("P2 sum: {}\n", .{sum});
}
