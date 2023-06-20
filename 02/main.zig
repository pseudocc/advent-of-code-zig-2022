const std = @import("std");

const Move = enum(u8) {
    Rock = 1,
    Paper = 2,
    Scissors = 3,
};

const Result = enum(u8) {
    Loss = 1,
    Draw = 2,
    Win = 3,
};

fn Round(comptime T: type) type {
    return struct {
        opponent: Move,
        player: T,

        const Self = @This();

        pub fn score(self: *const Self) u32 {
            var outcome_score: u32 = undefined;
            var shape_score: u32 = undefined;
            const opponent = @as(i32, @enumToInt(self.opponent));

            if (comptime T == Move) {
                const player = @as(i32, @enumToInt(self.player));
                shape_score = @intCast(u32, player);
                outcome_score = oc: {
                    const diff = player - opponent;
                    var result: u32 = 0;
                    if (diff == 0) {
                        result = 3;
                    } else if (diff == 1 or diff == -2) {
                        result = 6;
                    } else {
                        result = 0;
                    }
                    break :oc result;
                };
            } else if (comptime T == Result) {
                shape_score = @intCast(u32, opponent);
                switch (self.player) {
                    .Loss => {
                        outcome_score = 0;
                        if (shape_score == 1) {
                            shape_score = 3;
                        } else {
                            shape_score -= 1;
                        }
                    },
                    .Draw => {
                        outcome_score = 3;
                    },
                    .Win => {
                        outcome_score = 6;
                        if (shape_score == 3) {
                            shape_score = 1;
                        } else {
                            shape_score += 1;
                        }
                    },
                }
            } else {
                @compileError("invalid type");
            }

            return shape_score + outcome_score;
        }
    };
}

const RoundIterator = struct {
    reader: std.fs.File.Reader,

    const Self = @This();

    pub fn new(file: std.fs.File) Self {
        const reader = file.reader();
        return Self{ .reader = reader };
    }

    pub fn next(self: *Self, comptime T: type) ?Round(T) {
        const opponent = self.reader.readByte() catch return null;
        self.reader.skipBytes(1, .{}) catch return null;
        const player = self.reader.readByte() catch return null;
        defer self.reader.skipBytes(1, .{}) catch {};

        const opponent_offset: u8 = 'A' - 1;
        const player_offset: u8 = 'X' - 1;

        return Round(T){
            .opponent = @intToEnum(Move, opponent - opponent_offset),
            .player = @intToEnum(T, player - player_offset),
        };
    }
};

pub fn tournament(comptime T: type, comptime entry: []const u8) !u32 {
    const cwd = std.fs.cwd();
    const file = try cwd.openFile(entry, .{ .mode = .read_only });

    var iter = RoundIterator.new(file);
    defer iter.reader.context.close();

    var score: u32 = 0;
    while (true) {
        const round = iter.next(T) orelse break;
        score += round.score();
    }

    return score;
}

pub fn main() !void {
    var score: u32 = undefined;
    const stdout = std.io.getStdOut().writer();
    defer stdout.context.close();

    score = try tournament(Move, "test");
    try stdout.print("P1 test score: {}\n", .{score});

    score = try tournament(Result, "test");
    try stdout.print("P2 test score: {}\n", .{score});

    score = try tournament(Move, "input");
    try stdout.print("P1 score: {}\n", .{score});

    score = try tournament(Result, "input");
    try stdout.print("P2 score: {}\n", .{score});
}

test "single round" {
    const round_move = Round(Move){
        .opponent = Move.Rock,
        .player = Move.Paper,
    };
    try std.testing.expectEqual(round_move.score(), 8);

    const round_result = Round(Result){
        .opponent = Move.Rock,
        .player = Result.Win,
    };
    try std.testing.expectEqual(round_result.score(), 7);
}

test "round iterator" {
    const cwd = std.fs.cwd();
    const file = try cwd.openFile("test", .{ .mode = .read_only });

    var iter = RoundIterator.new(file);
    defer iter.reader.context.close();

    const expected_list = [_]Round(Move){
        Round(Move){
            .opponent = Move.Rock,
            .player = Move.Paper,
        },
        Round(Move){
            .opponent = Move.Paper,
            .player = Move.Rock,
        },
        Round(Move){
            .opponent = Move.Scissors,
            .player = Move.Scissors,
        },
    };

    for (expected_list) |expected| {
        const actual = iter.next(Move);
        try std.testing.expectEqual(expected, actual.?);
    }

    const actual = iter.next(Move);
    try std.testing.expect(actual == null);
}
