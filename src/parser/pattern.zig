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
                        self.end = self.start;
                        break :iblk PatternState{ .Final = 1 };
                    },
                    .number => PatternState{ .Intrem = 1 },
                };
            },
            .Final => self.reset(),
            .Intrem => |iq| switch (self.quantifier) {
                .any => PatternState{ .Intrem = iq + 1 },
                .one => self.reset(),
                .number => |number| if (iq == number) PatternState{ .Final = number } else PatternState{ .Intrem = iq + 1 },
            },
            else => .Init,
        } else switch (self.state) {
            .Intrem => switch (self.quantifier) {
                .any => .PostFinal,
                else => .Init,
            },
            else => .Init,
        };
    }
};
