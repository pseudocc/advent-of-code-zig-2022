const std = @import("std");

const input = struct {
    const example = @embedFile("example");
    const puzzle = @embedFile("puzzle");
};

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
    lines: std.mem.SplitIterator(u8),

    const Self = @This();

    pub fn new(raw: []const u8) Self {
        const lines = std.mem.split(u8, raw, "\n");
        return Self{ .lines = lines };
    }

    pub fn next(self: *Self, comptime T: type) ?Round(T) {
        const line = self.lines.next() orelse return null;
        var tokens = std.mem.tokenize(u8, line, " ");

        const opponent = tokens.next() orelse return null;
        const player = tokens.next() orelse return null;

        const opponent_offset: u8 = 'A' - 1;
        const player_offset: u8 = 'X' - 1;

        return Round(T){
            .opponent = @intToEnum(Move, opponent[0] - opponent_offset),
            .player = @intToEnum(T, player[0] - player_offset),
        };
    }
};

pub fn tournament(comptime T: type, comptime entry: []const u8) !u32 {
    var iter = RoundIterator.new(entry);

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

    score = try tournament(Move, input.example);
    try stdout.print("P1 test score: {}\n", .{score});

    score = try tournament(Result, input.example);
    try stdout.print("P2 test score: {}\n", .{score});

    score = try tournament(Move, input.puzzle);
    try stdout.print("P1 score: {}\n", .{score});

    score = try tournament(Result, input.puzzle);
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
    try std.testing.expectEqual(round_result.score(), 8);
}

test "round iterator" {
    var iter = RoundIterator.new(input.example);

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
