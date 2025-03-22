const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

const symbolm = @import("./symbol.zig");
const patternm = @import("./pattern.zig");
const lexemem = @import("./lexeme.zig");

const SymbolType = symbolm.SymbolType;
const Symbol = symbolm.Symbol;
const Pattern = patternm.Pattern;
const Quantifier = patternm.Quantifier;
const LexemeType = lexemem.LexemeType;
const Lexeme = lexemem.Lexeme;

pub const TokenType = enum {
    const Self = @This();
    LBrace,
    Word,
    Letter,
    Dot,
    RBrace,
    Gt,
    Lt,
    Comma,
    Dash,
    EOP,
    pub fn eq_symbol(self: Self, symbol_type: SymbolType) bool {
        const tag_name = std.enums.tagName(Self, self);
        const symbol_tag_name = std.enums.tagName(SymbolType, symbol_type);
        if (tag_name != null and symbol_tag_name != null) {
            return std.meta.eql(tag_name.?, symbol_tag_name.?);
        } else {
            return false;
        }
    }

    pub fn from_symbol(symbol_type: SymbolType) ?Self {
        const symbol_type_info = @typeInfo(@Type(symbol_type));
        const tags = std.enums.values(Self);
        return switch (symbol_type_info) {
            .@"enum" => |e| blk: {
                for (e.fields) |field| {
                    for (tags) |tag| {
                        const tag_name = std.enums.tagName(Self, tag);
                        if (tag_name) |tag_name_value| {
                            if (std.meta.eql(tag_name_value, field.name)) {
                                break :blk tag;
                            }
                        }
                    }
                }
                break :blk null;
            },
            else => null,
        };
    }

    pub fn to_symbol_type(self: Self) SymbolType {
        const symbol_types = std.enums.values(SymbolType);
        const tag_name_optional = std.enums.tagName(Self, self);
        for (symbol_types) |symbol_type| {
            const symbol_type_tag_name_optional = std.enums.tagName(SymbolType, symbol_type);
            if (tag_name_optional) |tag_name| {
                if (symbol_type_tag_name_optional) |symbol_type_tag_name| {
                    if (std.meta.eql(symbol_type_tag_name, tag_name)) {
                        return symbol_type;
                    }
                }
            }
        }
        return symbol_types[0];
    }
};

pub const Token = struct {
    const Self = @This();
    ttype: TokenType,
    value: ?[]u8,
    start: usize,
    end: usize,

    pub fn length(self: Self) usize {
        return @as(usize, self.end - self.start);
    }
};

pub const Tokenizer = struct {
    const Self = @This();
    patterns: []Pattern,
    allocator: Allocator,

    // this needs to verify for duplicates
    pub fn init(allocator: Allocator, patterns: []const struct { TokenType, LexemeType, Quantifier }) !Self {
        var _patterns = std.ArrayList(Pattern).init(allocator);
        for (patterns) |pattern| {
            try _patterns.append(Pattern.init(allocator, pattern[0], pattern[1], pattern[2]));
        }
        return Tokenizer{ .allocator = allocator, .patterns = _patterns.items };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self);
    }

    pub fn tokenize(self: *Self, lexemes: []Lexeme) ![]Token {
        var transition_result: []struct { Token, Pattern } = undefined;
        var tokens = std.ArrayList(Token).init(self.allocator);
        for (lexemes, 0..) |lexeme, i| {
            transition_result = try self.transition(lexeme, i);
            if (transition_result.len != 0) {
                const _tokens = tokens.items;
                // determine the most likely candidate based on Token.value length and Pattern quantifier
                var chosen_pair: struct { Token, Pattern } = transition_result[0];
                for (transition_result) |token_pattern_pair| {
                    const _token, const _pattern = token_pattern_pair;
                    //std.debug.print("step: {}: \n\tpattern = {}, quantifier = {}, value: {?s}\n", .{ i, _pattern.ttype, _pattern.ttype, _token.value });
                    const _ctoken, const _cpattern = chosen_pair;
                    if (_token.start == _ctoken.start) {
                        if (_pattern.quantifier == .one and _cpattern.quantifier == .any) {
                            chosen_pair = token_pattern_pair;
                        } else if (_pattern.quantifier == .number and _cpattern.quantifier == .any) {
                            chosen_pair = token_pattern_pair;
                        }
                    } else if (_token.start < _ctoken.start) {
                        chosen_pair = token_pattern_pair;
                    }
                }
                const _ctoken, _ = chosen_pair;
                for (_tokens, 0..) |_, j| {
                    const _token = _tokens[@as(usize, _tokens.len - 1 - j)];
                    if (_ctoken.start == _token.start and _ctoken.length() > _token.length()) {
                        tokens.shrinkAndFree(_tokens.len - j - 1);
                    }
                }
                try tokens.append(_ctoken);
            }
        }
        try tokens.append(Token{ .ttype = .EOP, .value = null, .start = lexemes.len, .end = lexemes.len });

        return tokens.items;
    }

    fn transition(self: *Self, lexeme: Lexeme, index: usize) ![]struct { Token, Pattern } {
        var tokens = std.ArrayList(struct { Token, Pattern }).init(self.allocator);
        for (self.patterns) |*_pattern| {
            const token = try _pattern.transition(lexeme, index);
            if (token) |_token| {
                try tokens.append(.{ _token, _pattern.* });
            }
        }
        return tokens.items;
    }

    fn getTokenPatterns(self: Self, ttype: TokenType) ![]Pattern {
        const token_patterns = std.ArrayList(Pattern).init(self.allocator);
        for (self.patterns) |pattern| {
            if (pattern.ttype == ttype) {
                try token_patterns.append(pattern);
            }
        }

        return token_patterns.items;
    }
};

test "TokenType test" {
    try expect(TokenType.Dash.eq_symbol(SymbolType.Dash));
    try expect(!TokenType.Dash.eq_symbol(SymbolType.Dot));
    //try expect(TokenType.Dot == TokenType.from_symbol(SymbolType.Dot).?);
    try expect(TokenType.Dot.to_symbol_type() == SymbolType.Dot);
}

test "Tokenizer test" {
    var tokenizer = try Tokenizer.init(std.heap.page_allocator, &.{
        .{ .RBrace, .rbrace, .one },
        .{ .LBrace, .lbrace, .one },
        .{ .Dot, .dot, .one },
        .{ .Comma, .comma, .one },
        .{ .Word, .literal, .any },
        .{ .Letter, .literal, .one },
        .{ .Dash, .dash, .one },
        .{ .Gt, .gt, .one },
        .{ .Lt, .lt, .one },
    });
    const lexemes = &[_]Lexeme{
        .dash,
        .{ .literal = 'd' },
        .comma,
        .space,
        .dash,
        .dash,
        .{ .literal = 'd' },
        .{ .literal = 'i' },
        .{ .literal = 'c' },
        .{ .literal = 'k' },
        .space,
        .lt,
        .{ .literal = 's' },
        .{ .literal = 'i' },
        .{ .literal = 'z' },
        .{ .literal = 'e' },
        .gt,
    };

    const tokens = try tokenizer.tokenize(@constCast(lexemes));
    //for (tokens) |token| {
    //    std.debug.print("token = {}, value = {?s} \n", .{ token.ttype, token.value });
    //}
    try expect(tokens.len == 10);
}
