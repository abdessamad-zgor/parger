const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

const symbolm = @import("./symbol.zig");
const patternm = @import("./pattern.zig");
const lexemem = @import("./lexeme.zig");

const SymbolType = symbolm.SymbolType;
const Symbol = symbolm.Symbol;
const Pattern = patternm.Pattern;
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
    ttype: TokenType,
    value: ?[]u8,
};

pub const Tokenizer = struct {
    const Self = @This();
    patterns: []Pattern,
    allocator: Allocator,

    pub fn init(allocator: Allocator, patterns: []Pattern) Self {
        return Tokenizer{ .allocator = allocator, .patterns = patterns };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self);
    }

    pub fn tokenize(self: Self, lexemes: []Lexeme) ![]Token {
        var recognizedPattern: ?Pattern = null;
        var tokens_arr = std.ArrayList(Token).init(self.allocator);
        for (lexemes, 0..) |lexeme, i| {
            recognizedPattern = self.transition(lexeme, i);
            if (recognizedPattern) |pattern| {
                const range = if (pattern.end == lexemes.len - 1) lexemes[pattern.start..] else lexemes[pattern.start .. pattern.end + 1];
                var result_token = std.ArrayList(u8).init(self.allocator);
                for (range) |lxm| {
                    try result_token.append(lxm.to_char());
                }
                try tokens_arr.append(Token{ .ttype = pattern.ttype, .value = result_token.items });
            }
        }
        try tokens_arr.append(Token{ .ttype = .EOP, .value = null });

        return tokens_arr.items;
    }

    pub fn transition(self: Self, lexeme: Lexeme, index: usize) ?Pattern {
        var final_pattern: ?Pattern = null;
        for (self.patterns) |ptn| {
            var pattern = ptn;
            pattern.transition(lexeme, index);
            if (pattern.state == .Final or pattern.state == .PostFinal) {
                final_pattern = pattern;
                break;
            }
        }
        return final_pattern;
    }
};

test "TokenType test" {
    try expect(TokenType.Dash.eq_symbol(SymbolType.Dash));
    try expect(!TokenType.Dash.eq_symbol(SymbolType.Dot));
}
