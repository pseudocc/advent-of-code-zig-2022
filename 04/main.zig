const std = @import("std");

const input = struct {
    const example = @embedFile("example");
    const puzzle = @embedFile("puzzle");
};

const Range = struct {
    start: usize,
    end: usize,

    const Self = @This();

    pub fn contains(self: *const Self, other: *const Self) bool {
        return self.start <= other.start and self.end >= other.end;
    }
};

const ParseError = error{
    Invalid,
};

fn parse_range(range: []const u8) !Range {
    var tokens = std.mem.tokenize(u8, range, "-");
    var numbers: [2]usize = undefined;

    inline for (0..numbers.len) |i| {
        var token = tokens.next() orelse return ParseError.Invalid;
        numbers[i] = try std.fmt.parseUnsigned(usize, token, 0);
    }

    return Range{ .start = numbers[0], .end = numbers[1] };
}

fn parse_line(line: []const u8) ![2]Range {
    var ranges = std.mem.tokenize(u8, line, ",");
    var result: [2]Range = undefined;

    inline for (0..result.len) |i| {
        var range = ranges.next() orelse return ParseError.Invalid;
        result[i] = try parse_range(range);
    }

    return result;
}

pub fn fully_contained(ranges: [2]Range) bool {
    return ranges[0].contains(&ranges[1]) //
    or ranges[1].contains(&ranges[0]);
}

pub fn main() !void {
    var lines = std.mem.tokenize(u8, input.puzzle, "\n");
    var n_fully_contained: usize = 0;

    while (lines.next()) |line| {
        var ranges = try parse_line(line);
        if (fully_contained(ranges)) {
            n_fully_contained += 1;
        }
    }

    std.log.debug("n_fully_contained: {d}\n", .{n_fully_contained});
}

test "example" {
    var lines = std.mem.tokenize(u8, input.example, "\n");
    var n_fully_contained: usize = 0;

    while (lines.next()) |line| {
        var ranges = try parse_line(line);
        if (fully_contained(ranges)) {
            n_fully_contained += 1;
        }
    }

    try std.testing.expect(n_fully_contained == 2);
}
