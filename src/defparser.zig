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
const Pattern = parser.Pattern;
const Rule = parser.Rule;
const Symbol = parser.Symbol;
const Grammer = parser.Grammer;
const Parser = parser.Parser;

pub const DefParser = struct {
    const Self = @This();
    allocator: Allocator,
    parser: Parser,

    fn init(allocator: Allocator) Self {
        const tokenizer = Tokenizer.init(allocator, @constCast(&[_]Pattern{ Pattern.init(allocator, .RBrace, .rbrace, .one), Pattern.init(allocator, .LBrace, .lbrace, .one), Pattern.init(allocator, .Dot, .dot, .one), Pattern.init(allocator, .Comma, .comma, .one), Pattern.init(allocator, .Word, .literal, .any), Pattern.init(allocator, .Letter, .literal, .one), Pattern.init(allocator, .Dash, .dash, .one), Pattern.init(allocator, .Gt, .gt, .one), Pattern.init(allocator, .Lt, .lt, .one) }));

        const grammer = Grammer.init(allocator, .Def, &.{
            Rule.init(.Required, &.{ .Lt, .Word, .Gt }),
            Rule.init(.RequiredVariadic, &.{ .Lt, .Word, .Dot, .Dot, .Dot, .Gt }),
            Rule.init(.Optional, &.{ .LBrace, .Word, .RBrace }),
            Rule.init(.OptionalVariadic, &.{
                .LBrace,
                .Word,
                .Dot,
                .Dot,
                .Dot,
                .RBrace,
            }),
            Rule.init(.Variadic, &.{.OptionalVariadic}),
            Rule.init(.Variadic, &.{.RequiredVariadic}),
            Rule.init(.Argument, &.{
                .Required,
            }),
            Rule.init(.Argument, &.{.Optional}),
            Rule.init(.Argument, &.{.Variadic}),
            Rule.init(.ShortFlag, &.{ .Dash, .Letter }),
            Rule.init(.LongFlag, &.{
                .Dash,
                .Dash,
                .Word,
            }),
            Rule.init(.Flag, &.{
                .ShortFlag,
            }),
            Rule.init(.Flag, &.{
                .LongFlag,
            }),
            Rule.init(.Flag, &.{ .ShortFlag, .Comma, .LongFlag }),
            Rule.init(.ArgumentList, &.{.Argument}),
            Rule.init(.ArgumentList, &.{
                .Argument,
                .ArgumentList,
            }),
            Rule.init(.ArgumentList, &.{}),
            Rule.init(.OptionDef, &.{ .Flag, .ArgumentList }),
        });

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
        const ast = try self.parser.parse(lexemes);
        return ast;
    }
};

test "lex a def" {
    var defParser = DefParser.init(std.heap.page_allocator);
    const lexemes = try defParser.lex(@constCast("-d, --dick <size>"));
    std.debug.print("lexemes length: {}\n", .{lexemes.len});
}

test "parse a def" {
    var defParser = DefParser.init(std.heap.page_allocator);
    _ = try defParser.parse(@constCast("-d, --dick <size>"));
    //try std.testing.expect(@TypeOf(parse_tree) == Node);
}
