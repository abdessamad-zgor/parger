const std = @import("std");
const expect = std.testing.expect;

const lexemem = @import("./lexeme.zig");
const tokenm = @import("./token.zig");

const TokenType = tokenm.TokenType;
const Token = tokenm.Token;
const LexemeType = lexemem.LexemeType;

pub const QuantifierType = enum {
    any,
    one,
    number,
};

pub const Quantifier = union(QuantifierType) {
    any: void,
    one: void,
    number: usize,
};

pub const StateType = enum { Init, Intrem, Final, PostFinal };

pub const PatternState = union(StateType) {
    Init: void,
    Intrem: usize,
    Final: usize,
    PostFinal: void,
};

pub const Pattern = struct {
    const Self = @This();
    lexeme: LexemeType,
    quantifier: Quantifier,
    state: PatternState,
    ttype: TokenType,
    start: usize,
    end: usize,

    // for this use case, tokens comprizing of one single type of lexeme are acceptable but subsequent implementation
    // need to replace lexeme with regular expression
    pub fn init(ttype: TokenType, lexeme: LexemeType, quantifier: Quantifier) Self {
        return Pattern{ .lexeme = lexeme, .quantifier = quantifier, .ttype = ttype, .start = 0, .end = 0, .state = .Init };
    }

    pub fn reset(self: *Self) PatternState {
        self.start = 0;
        self.end = 0;
        return .Init;
    }

    pub fn transition(self: *Self, lexeme: LexemeType, index: usize) void {
        self.state = if (lexeme == self.lexeme) switch (self.state) {
            .Init => blk: {
                self.start = index;
                break :blk switch (self.quantifier) {
                    .any => PatternState{ .Intrem = 1 },
                    .one => iblk: {
                        self.end = self.start + 1;
                        break :iblk PatternState{ .Final = 1 };
                    },
                    .number => PatternState{ .Intrem = 1 },
                };
            },
            .Final => self.reset(),
            .Intrem => |iq| switch (self.quantifier) {
                .any => PatternState{ .Intrem = iq + 1 },
                .one => self.reset(),
                .number => |number| blk: {
                    if (iq == number) {
                        self.end = iq;
                        break :blk PatternState{ .Final = number };
                    } else {
                        break :blk PatternState{ .Intrem = iq + 1 };
                    }
                },
            },
            else => .Init,
        } else switch (self.state) {
            .Intrem => switch (self.quantifier) {
                .any => blk: {
                    self.end = @intCast(index - 1);
                    break :blk .PostFinal;
                },
                else => self.reset(),
            },
            else => self.reset(),
        };
    }
};

test "Pattern test" {
    var word_pattern = Pattern.init(.Word, .literal, .any);
    const lexemes: [6]LexemeType = .{ .literal, .literal, .literal, .literal, .literal, .dash };
    for (lexemes, 0..) |lexeme, i| {
        word_pattern.transition(lexeme, i);
        if (i == 5) {
            try expect(word_pattern.start == 0);
            try expect(word_pattern.end == 4);
            std.debug.print("start: {}, end: {} \n", .{ word_pattern.start, word_pattern.end });
        }
    }
}
