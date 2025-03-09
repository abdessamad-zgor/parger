const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

const lexemem = @import("./lexeme.zig");
const tokenm = @import("./token.zig");

const TokenType = tokenm.TokenType;
const Token = tokenm.Token;
const LexemeType = lexemem.LexemeType;
const Lexeme = lexemem.Lexeme;

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

pub const StateType = enum { Init, Intrem, Final };

pub const PatternState = union(StateType) {
    Init: void,
    Intrem: usize,
    Final: usize,
};

pub const Pattern = struct {
    const Self = @This();
    lexeme: LexemeType,
    quantifier: Quantifier,
    state: PatternState,
    ttype: TokenType,
    stack: ?std.ArrayList(u8),
    allocator: ?Allocator,
    start: usize,
    end: usize,

    // for this use case, tokens comprizing of one single type of lexeme are acceptable but subsequent implementation
    // need to replace lexeme with regular expression
    pub fn init(allocator: ?Allocator, ttype: TokenType, lexeme: LexemeType, quantifier: Quantifier) Self {
        var stack: ?std.ArrayList(u8) = null;
        if (allocator) |_allocator| {
            stack = std.ArrayList(u8).init(_allocator);
        }
        return Pattern{ .stack = stack, .allocator = allocator, .lexeme = lexeme, .quantifier = quantifier, .ttype = ttype, .start = 0, .end = 0, .state = .Init };
    }

    pub fn reset(self: *Self) PatternState {
        self.start = 0;
        self.end = 0;
        if (self.stack != null) {
            self.stack = std.ArrayList(u8).init(self.allocator.?);
        }
        return .Init;
    }

    pub fn transition(self: *Self, lexeme: Lexeme, index: usize) !?Token {
        if (self.stack != null) {
            try self.stack.?.append(lexeme.to_char());
        }
        self.state = if (lexeme == self.lexeme) switch (self.state) {
            .Init => blk: {
                self.start = index;
                break :blk switch (self.quantifier) {
                    .one, .any => iblk: {
                        self.end = self.start + 1;
                        break :iblk PatternState{ .Final = 1 };
                    },
                    .number => PatternState{ .Intrem = 1 },
                };
            },
            .Final => |iq| blk: {
                break :blk switch (self.quantifier) {
                    .any => iblk: {
                        self.end = self.end + 1;
                        break :iblk PatternState{ .Final = iq + 1 };
                    },
                    .one => iblk: {
                        self.start = index;
                        self.end = self.start + 1;
                        break :iblk PatternState{ .Final = 1 };
                    },
                    else => self.reset(),
                };
            },
            .Intrem => |iq| switch (self.quantifier) {
                .any => iblk: {
                    self.end = self.end + 1;
                    break :iblk PatternState{ .Final = iq + 1 };
                },
                .one => self.reset(),
                .number => |number| blk: {
                    if (iq == number) {
                        self.end = self.start + iq;
                        break :blk PatternState{ .Final = number };
                    } else {
                        break :blk PatternState{ .Intrem = iq + 1 };
                    }
                },
            },
        } else self.reset();

        if (self.ttype == .Word) {
            std.debug.print("step {}:\n\tstate = {}, stack = {s}, start = {}, end = {}\n", .{ index, self.state, self.stack.?.items, self.start, self.end });
        }

        if (self.state == .Final) {
            return if (self.stack != null) Token{ .ttype = self.ttype, .value = self.stack.?.items, .start = self.start, .end = self.end } else Token{ .ttype = self.ttype, .value = null, .start = self.start, .end = self.end };
        }

        return null;
    }
};

test "Pattern test" {
    var word_pattern = Pattern.init(std.heap.page_allocator, .Word, .literal, .any);
    const lexemes: [6]Lexeme = .{ .{ .literal = 'z' }, .{ .literal = 'i' }, .{ .literal = 'i' }, .{ .literal = 'i' }, .{ .literal = 'g' }, .dash };
    for (lexemes, 0..) |lexeme, i| {
        _ = try word_pattern.transition(lexeme, i);
        //try expect(word_pattern.start == 0);
        //try expect(word_pattern.end == 4);
        //try expect(std.mem.eql(u8, @as([]const u8, token.?.value.?), "ziiig"));
        //std.debug.print("start: {}, end: {} \n", .{ word_pattern.start, word_pattern.end });
    }
}
