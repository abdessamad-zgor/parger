const std = @import("std");
const Allocator = std.mem.Allocator;
const parser = @import("./parser/parser.zig");

const NodeType = parser.NodeType;
const Node = parser.Node;
const TokenType = parser.TokenType;
const Token = parser.Token;
const Tokenizer = parser.Tokenizer;
const Lexeme = parser.Lexeme;
const LexemeType = parser.LexemeType;
const StateType = parser.StateType;
const Quantifier = parser.Quantifier;
const Pattern = parser.Pattern;
const Rule = parser.Rule;
const SymbolType = parser.SymbolType;
const Symbol = parser.Symbol;
const Grammer = parser.Grammer;
const Parser = parser.Parser;

pub const DefParser = struct {
    const Self = @This();
    allocator: Allocator,
    parser: Parser,

    fn init(allocator: Allocator) !Self {
        var patterns = std.ArrayList(struct { TokenType, LexemeType, Quantifier }).init(allocator);
        try patterns.appendSlice(&.{
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
        const tokenizer = try Tokenizer.init(allocator, patterns.items);

        var rules = std.ArrayList(struct { NodeType, []const []const SymbolType }).init(allocator);
        try rules.appendSlice(&.{
            .{
                .Required,
                &.{
                    &.{ .Lt, .Word, .Gt },
                },
            },
            .{
                .RequiredVariadic, &.{
                    &.{ .Lt, .Word, .Dot, .Dot, .Dot, .Gt },
                },
            },
            .{
                .Optional,
                &.{
                    &.{ .LBrace, .Word, .RBrace },
                },
            },
            .{
                .OptionalVariadic, &.{
                    &.{ .LBrace, .Word, .Dot, .Dot, .Dot, .RBrace },
                },
            },
            .{
                .Variadic, &.{
                    &.{.OptionalVariadic},
                    &.{.RequiredVariadic},
                },
            },
            .{
                .Argument, &.{
                    &.{.Required},
                    &.{.Optional},
                    &.{.Variadic},
                },
            },
            .{
                .ShortFlag,
                &.{
                    &.{ .Dash, .Letter },
                },
            },
            .{
                .LongFlag,
                &.{
                    &.{ .Dash, .Dash, .Word },
                },
            },
            .{
                .Flag, &.{
                    &.{ .ShortFlag, .Comma, .LongFlag },
                    &.{.LongFlag},
                    &.{.ShortFlag},
                },
            },
            .{
                .ArgumentList, &.{
                    &.{.Argument},
                    &.{ .Argument, .ArgumentList },
                    &.{},
                },
            },
            .{
                .OptionDef,
                &.{
                    &.{ .Flag, .ArgumentList },
                },
            },
            .{
                .CommandDef, &.{
                    &.{ .Word, .ArgumentList },
                },
            },
            .{
                .Def,
                &.{
                    &.{.OptionDef},
                    &.{.CommandDef},
                },
            },
        });
        const grammer = try Grammer.init(allocator, .Def, rules.items);

        const def_parser = Parser.init(allocator, grammer, tokenizer);

        return DefParser{ .allocator = allocator, .parser = def_parser };
    }

    fn deinit(self: Self) void {
        self.allocator.free(self);
    }

    fn lex(self: Self, def_string: []u8) ![]Lexeme {
        var lexeme_opt: ?Lexeme = null;
        var lexemes = std.ArrayList(Lexeme).init(self.allocator);
        for (def_string) |char| {
            lexeme_opt = switch (char) {
                '-' => .dash,
                '<' => .lt,
                '>' => .gt,
                '[' => .lbrace,
                ']' => .rbrace,
                ',' => .comma,
                '.' => .dot,
                ' ' => .space,
                48...57 => .{ .literal = char },
                65...90 => .{ .literal = char },
                97...120 => .{ .literal = char },
                else => null,
            };
            if (lexeme_opt) |lexeme| {
                try lexemes.append(lexeme);
            }
        }

        return lexemes.items;
    }

    fn parse(self: *Self, def_string: []u8) !Node {
        const lexemes = try self.lex(def_string);
        var _parser = self.parser;
        const ast = try _parser.parse(lexemes);
        return ast;
    }
};

test "lex a def" {
    var defParser = try DefParser.init(std.heap.page_allocator);
    const lexemes = try defParser.lex(@constCast("-d, --dick <size>"));
    std.debug.print("lexemes length: {}\n", .{lexemes.len});
}

test "parse a def" {
    var defParser = try DefParser.init(std.heap.page_allocator);
    const parse_tree = try defParser.parse(@constCast("-d, --dick <size>"));
    try std.testing.expect(@TypeOf(parse_tree) == Node);
    std.debug.print("parser stack : {any}\n", .{defParser.parser.stack.items});
    try std.testing.expect(defParser.parser.stack.items.len == 1);
    std.debug.print("parse tree: {any}\n", .{parse_tree});
}
