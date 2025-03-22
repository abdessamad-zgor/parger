const std = @import("std");
const Allocator = std.mem.Allocator;

pub const rulem = @import("./rule.zig");
pub const patternm = @import("./pattern.zig");
pub const nodem = @import("./node.zig");
pub const symbolm = @import("./symbol.zig");
pub const tokenm = @import("./token.zig");
pub const lexemem = @import("./lexeme.zig");
pub const grammerm = @import("./grammer.zig");

pub const Quantifier = patternm.Quantifier;
pub const Rule = rulem.Rule;
pub const NodeType = nodem.NodeType;
pub const Node = nodem.Node;
pub const SymbolType = symbolm.SymbolType;
pub const Symbol = symbolm.Symbol;
pub const TokenType = tokenm.TokenType;
pub const Token = tokenm.Token;
pub const LexemeType = lexemem.LexemeType;
pub const Lexeme = lexemem.Lexeme;
pub const Tokenizer = tokenm.Tokenizer;
pub const Grammer = grammerm.Grammer;

const ParserState = enum {
    Init,
    Intrem,
    Accept,
    Reject,
};

const ParseStep = struct {
    index: usize,
    step: union(enum) {
        shift: void,
        reduce: struct {
            rule: Rule,
            variant: usize,
            stack: []SymbolType,
            stack_index: usize,
        },
    },
};

pub const Parser = struct {
    const Self = @This();
    allocator: Allocator,
    tokenizer: Tokenizer,
    grammer: Grammer,
    tokens: []Token,
    current_index: usize,
    parse_table: std.ArrayList(ParseStep),
    stack: std.ArrayList(SymbolType),
    state: ParserState,

    pub fn init(allocator: Allocator, grammer: Grammer, tokenizer: Tokenizer) Self {
        return Parser{ .allocator = allocator, .grammer = grammer, .tokenizer = tokenizer, .tokens = &.{}, .parse_table = std.ArrayList(ParseStep).init(allocator), .stack = std.ArrayList(SymbolType).init(allocator), .state = .Init, .current_index = 0 };
    }

    pub fn parse(self: *Self, lexemes: []Lexeme) !Node {
        //self.tokens = try self.tokenizer.tokenize(lexemes);
        //while (index < self.tokens.len) : ({
        //    try self.shift();
        //}) {
        //    try self.reduce();
        //} else {
        //    std.debug.print("parser stack length: {}\n", .{self.stack.items.len});
        //    return self.stack.items[0].value.node;
        //}

        self.tokens = try self.tokenizer.tokenize(lexemes);
        while (self.current_index < self.tokens.len) {
            const lookahead = self.tokens[self.current_index];
            if (self.reduce()) |reduce_result| {
                _ = reduce_result;
            } else {
                self.shift();
            }
            try self.stack.append(@constCast(lookahead).to_symbol_type());
        }
    }

    pub fn reduce(self: *Self) !struct { ?Rule, usize } {
        _ = self;
        //var reducer_rule, var stack_index = self.grammer.accept(self.stack.items);
        //while (reducer_rule != null) : ({
        //    reducer_rule, stack_index = self.grammer.accept(self.stack.items);
        //}) {
        //    if (reducer_rule) |rule| {
        //        try self.step(index, rule);
        //        const rule_stack = self.stack.items[@intCast(stack_index)..];
        //        std.debug.print("stack: {}, rule: {}, index: {}\n", .{ self.stack, rule.ntype, stack_index });
        //        const reduced_node = try rule.reduce(self.allocator, @constCast(rule_stack), @intCast(stack_index));
        //    }
        //}
    }

    pub fn shift(self: *Self) !void {
        //try self.step(self.current_indexndex.*, null);
        //const current_token = self.tokens[index.*];
        //try self.stack.append(Symbol{ .stype = TokenType.to_symbol_type(current_token.ttype), .value = .{ .token = current_token } });
        //index.* += 1;
        self.current_index += 1;
    }

    //pub fn symbols_stack(self: Self) ![]SymbolType {
    //    var symbols_type_stack = std.ArrayList(SymbolType).init(self.allocator);
    //    for (self.stack.items) |symbol| {
    //        try symbols_type_stack.append(symbol.stype);
    //    }
    //    return symbols_type_stack.items;
    //}

    //fn step(self: *Self, index: usize, rule: ?Rule) !void {
    //    if (rule) |nrule| {
    //        try self.parse_table.append(ParseStep{ .index = index, .step = .{ .reduce = nrule } });
    //    } else {
    //        try self.parse_table.append(ParseStep{ .index = index, .step = .shift });
    //    }
    //}
};
