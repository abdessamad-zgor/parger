const std = @import("std");
const Allocator = std.mem.Allocator;

const rulem = @import("./rule.zig");
const nodem = @import("./node.zig");
const symbolm = @import("./symbol.zig");
const tokenm = @import("./token.zig");
const lexemem = @import("./lexeme.zig");
const grammerm = @import("./grammer.zig");

const Rule = rulem.Rule;
const NodeType = nodem.NodeType;
const Node = nodem.Node;
const SymbolType = symbolm.SymbolType;
const Symbol = symbolm.Symbol;
const TokenType = tokenm.Token;
const Token = tokenm.Token;
const Lexeme = lexemem.Lexeme;
const Tokenizer = tokenm.Tokenizer;
const Grammer = grammerm.Grammer;

const ParserState = enum {
    Init,
    Intrem,
    Accept,
    Reject,
};

const ParseStep = struct { index: usize, step: union(enum) {
    shift: void,
    reduce: Rule,
} };

pub const Parser = struct {
    const Self = @This();
    allocator: Allocator,
    tokenizer: Tokenizer,
    grammer: Grammer,
    tokens: []Token,
    parse_table: std.ArrayList(ParseStep),
    stack: std.ArrayList(Symbol),
    state: ParserState,

    pub fn init(allocator: Allocator, grammer: Grammer, tokenizer: Tokenizer) Self {
        return Parser{ .allocator = allocator, .grammer = grammer, .tokenizer = tokenizer, .tokens = &.{}, .parse_table = std.ArrayList(ParseStep).init(allocator), .stack = std.ArrayList(Symbol).init(allocator), .state = .Init };
    }

    pub fn parse(self: *Self, lexemes: []Lexeme) !Node {
        self.tokens = try self.tokenizer.tokenize(lexemes);
        var index: usize = 0;
        while (self.state != .Accept or self.state != .Reject) : ({
            try self.shift(&index);
        }) {
            try self.reduce(index);
        } else {
            if (self.state == .Accept) {
                return self.stack.items[0].value.node;
            } else {
                return error.InvalidInput;
            }
        }
    }

    pub fn reduce(self: *Self, index: usize) !void {
        var reducer_rule, var stack_index = self.grammer.accept(try self.symbols_stack());
        while (reducer_rule != null) : ({
            reducer_rule, stack_index = self.grammer.accept(try self.symbols_stack());
        }) {
            if (reducer_rule) |rule| {
                try self.step(index, rule);
                try self.stack.insert(@intCast(stack_index), Symbol{ .stype = rule.ntype.to_symbol_type(), .value = .{ .node = try rule.reduce(self.allocator, (try self.symbols_stack())[@intCast(stack_index)..], self.stack.items[@intCast(stack_index)..], @intCast(stack_index)) } });
                self.stack.shrinkAndFree(@intCast(stack_index + 1));
            }
        }
    }

    pub fn shift(self: *Self, index: *usize) !void {
        try self.step(index.*, null);
        const current_token = self.tokens[index.*];
        try self.stack.append(Symbol{ .stype = TokenType.to_symbol_type(current_token.ttype), .value = .{ .token = current_token } });
        index.* += 1;
    }

    pub fn symbols_stack(self: Self) ![]SymbolType {
        var symbols_type_stack = std.ArrayList(SymbolType).init(self.allocator);
        for (self.stack.items) |symbol| {
            try symbols_type_stack.append(symbol.stype);
        }
        return symbols_type_stack.items;
    }

    fn step(self: *Self, index: usize, rule: ?Rule) !void {
        if (rule) |nrule| {
            try self.parse_table.append(ParseStep{ .index = index, .step = .{ .reduce = nrule } });
        } else {
            try self.parse_table.append(ParseStep{ .index = index, .step = .shift });
        }
    }
};
