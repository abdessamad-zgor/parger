const std = @import("std");
const Allocator = std.mem.Allocator;
const parser = @import("./parser.zig");

const NodeType = parser.NodeType;
const Node = parser.ASTNode;
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
        const tokenizer = Tokenizer.init(allocator, @constCast(&[_]Pattern{ Pattern.init(.RBrace, .rbrace, .one), Pattern.init(.LBrace, .lbrace, .one), Pattern.init(.Dot, .dot, .one), Pattern.init(.Comma, .comma, .one), Pattern.init(.Word, .literal, .any), Pattern.init(.Letter, .literal, .one), Pattern.init(.Dash, .dash, .one), Pattern.init(.Gt, .gt, .one), Pattern.init(.Lt, .lt, .one) }));

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

    fn lex(self: Self, def_string: []u8) []Lexeme {
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
                48...57 => .{ .literal = char },
                65...90 => .{ .literal = char },
                97...120 => .{ .literal = char },
                else => null,
            };
            if (lexeme_opt) |lexeme| {
                lexemes.append(lexeme) catch |err| {
                    std.log.err("Allocation Error: failed to allocate new Lexeme on lexemes {}", .{err});
                    std.process.exit(1);
                };
            }
        }

        return lexemes.items;
    }

    fn parse(self: *Self, def_string: []u8) !Node {
        const lexemes = self.lex(def_string);
        return self.parser.parse(lexemes);
    }
};

test "lex a def" {
    var defParser = DefParser.init(std.heap.page_allocator);
    const lexemes = defParser.lex(@constCast("-d, --dick <size>"));
    try std.testing.expect(lexemes.len == 15);
}

test "parse a def" {
    var defParser = DefParser.init(std.heap.page_allocator);
    const parse_tree = try defParser.parse(@constCast("-d, --dick <size>"));
    try std.testing.expect(@TypeOf(parse_tree) == Node);
}
