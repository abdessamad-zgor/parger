const std = @import("std");
const Allocator = std.mem.Allocator;

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
            return std.meta.eql(tag_name.?.*, symbol_tag_name.?.*);
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
pub const NodeType = enum {
    const Self = @This();
    Required,
    Optional,
    RequiredVariadic,
    OptionalVariadic,
    Variadic,
    Argument,
    ShortFlag,
    LongFlag,
    Flag,
    ArgumentList,
    CommandDef,
    OptionDef,
    Def,
    pub fn eq_symbol(self: Self, symbol_type: SymbolType) bool {
        const tag_name = std.enums.tagName(Self, self);
        const symbol_tag_name = std.enums.tagName(SymbolType, symbol_type);
        if (tag_name != null and symbol_tag_name != null) {
            return std.meta.eql(tag_name.?.*, symbol_tag_name.?.*);
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

pub fn MergeEnums(comptime EnumA: type, comptime EnumB: type) type {
    const token_fields = blk: {
        switch (@typeInfo(EnumA)) {
            .@"enum" => |e| break :blk e.fields,
            else => @compileError(@typeName(EnumA) ++ " must be an enum"),
        }
    };

    const node_fields = blk: {
        switch (@typeInfo(EnumB)) {
            .@"enum" => |e| break :blk e.fields,
            else => @compileError(@typeName(EnumB) ++ " must be an enum"),
        }
    };

    var fields: [token_fields.len + node_fields.len]std.builtin.Type.EnumField = undefined;

    for (token_fields, 0..) |f, i| {
        fields[i] = f;
    }

    for (node_fields, token_fields.len..) |f, i| {
        fields[i] = .{ .name = f.name, .value = @intCast(f.value + i) };
    }

    return @Type(.{ .@"enum" = .{
        .decls = &.{},
        .tag_type = i16,
        .fields = &fields,
        .is_exhaustive = true,
    } });
}

pub const SymbolType = MergeEnums(TokenType, NodeType);

pub const Symbol = struct { stype: SymbolType, value: union { token: Token, node: ASTNode } };

const LexemeType = enum {
    dash,
    literal,
    dot,
    lbrace,
    rbrace,
    gt,
    lt,
    comma,
    space,
    equals,
};

pub const Token = struct {
    ttype: TokenType,
    value: ?[]u8,
};

pub const Lexeme = union(LexemeType) {
    dash: void,
    literal: u8,
    dot: void,
    lbrace: void,
    rbrace: void,
    gt: void,
    lt: void,
    comma: void,
    space: void,
    equals: void,
};

pub const ASTNode = struct {
    ntype: NodeType,
    tokens: ?[]Token,
    nodes: ?[]ASTNode,
    index: usize,

    pub fn init(ntype: NodeType, value: ?[]Token, nodes: ?[]ASTNode, index: usize) ASTNode {
        return ASTNode{ .ntype = ntype, .value = value, .nodes = nodes, .index = index };
    }
};

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
    ttoken: TokenType,
    start: usize,
    end: usize,

    pub fn init(ttoken: TokenType, lexeme: LexemeType, quantifier: Quantifier) Self {
        return Pattern{ .lexeme = lexeme, .quantifier = quantifier, .ttoken = ttoken, .start = 0, .end = 0, .state = .Init };
    }

    pub fn reset(self: Self) PatternState {
        self.start = 0;
        self.end = 0;
        return .Init;
    }

    pub fn transition(self: Self, lexeme: LexemeType, index: usize) void {
        self.state = if (lexeme == self.lexeme) switch (self.state) {
            .Init => {
                self.start = index;
                return switch (self.quantifier) {
                    .any => PatternState{ .Itrem = 1 },
                    .one => blk: {
                        self.end = self.start;
                        break :blk PatternState{ .Final = 1 };
                    },
                    .number => PatternState{ .Itrem = 1 },
                };
            },
            .Final => self.reset(),
            .Intrem => |iq| switch (self.quantifier) {
                .any => PatternState{ .Intrem = iq + 1 },
                .one => self.reset(),
                .number => |number| if (iq == number) PatternState{ .Final = number } else PatternState{ .Intrem = iq + 1 },
            },
        } else switch (self.state) {
            .Intrem => |qi| switch (self.quantifier) {
                .any => PatternState{ .PostFinal = qi },
                else => .Init,
            },
            else => .Init,
        };
    }
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
        const recognizedPattern: ?Pattern = null;
        var tokens_arr = std.ArrayList(Token).init(self.allocator);
        for (lexemes) |lexeme| {
            recognizedPattern = self.transition(lexeme);
            if (recognizedPattern) |pattern| {
                const range = if (pattern.end == lexemes.len - 1) lexemes[pattern.start..] else lexemes[pattern.start .. pattern.end + 1];
                try tokens_arr.append(Token{ .ttype = pattern.ttype, .value = range });
            }
        }
        try tokens_arr.append(Token{ .ttype = .EOP, .value = null });

        return tokens_arr.items;
    }

    pub fn transition(self: Self, lexeme: Lexeme) ?Pattern {
        var final_pattern: ?Pattern = null;
        for (self.patterns) |pattern| {
            pattern.transition(lexeme);
            if (pattern.state == .Final or pattern.state == .PostFinal) {
                final_pattern = pattern;
                break;
            }
        }
        return final_pattern;
    }
};

pub const Rule = struct {
    const Self = @This();
    ntype: NodeType,
    symbols: []SymbolType,

    pub fn init(ntype: NodeType, symbols: []SymbolType) Self {
        return Rule{ .ntype = ntype, .symbols = symbols };
    }

    pub fn accept(self: Self, stack: []SymbolType) bool {
        if (self.symbols.len != stack.len) {
            return false;
        }
        for (self.symbols, 0..) |symbol, i| {
            if (!std.meta.eql(symbol, stack[i])) {
                return false;
            }
        }
        return true;
    }

    pub fn reduce(self: Self, symbol_stack: []SymbolType, stack: []Symbol, index: usize) !ASTNode {
        if (!self.accept(symbol_stack)) {
            return error.InvalidSymbolStack;
        }

        const reduced_node = ASTNode.init(self.ntype, stack, index);
        return reduced_node;
    }
};

pub const Grammer = struct {
    const Self = @This();
    allocator: Allocator,
    rules: []Rule,
    entry_point: NodeType,

    pub fn init(allocator: Allocator, entry_point: NodeType, rules: []Rule) Self {
        return Grammer{ .allocator = allocator, .entry_point = entry_point, .rules = rules };
    }

    pub fn accept(self: Self, symbols: []SymbolType) struct { ?Rule, i32 } {
        var accepted_rule: ?Rule = null;
        var stack_index = -1;
        for (symbols, 0..) |_, i| {
            const symbols_slice = symbols[@intCast(symbols.len - 1 - i)..];
            for (self.rules) |rule| {
                if (rule.accept(symbols_slice) and i > stack_index) {
                    accepted_rule = rule;
                    stack_index = i;
                }
            }
        }
        return .{ accepted_rule, stack_index };
    }
};

const ParserState = enum {
    Init,
    Intrem,
    Accept,
    Reject,
};

pub const Parser = struct {
    const Self = @This();
    allocator: Allocator,
    tokenizer: Tokenizer,
    grammer: Grammer,
    stack: std.ArrayList(Symbol),
    state: ParserState,

    pub fn init(allocator: Allocator, entry_point: NodeType, grammer: Grammer, tokenizer: Tokenizer) Self {
        return Parser{ .entry_point = entry_point, .grammer = grammer, .tokenizer = tokenizer, .stack = std.ArrayList(Token).init(allocator), .state = .Init };
    }

    pub fn parse(self: Self, lexemes: []Lexeme) !ASTNode {
        const tokens = try self.tokenizer.tokenize(lexemes);
        var index = -1;
        while (self.state != .Accept or self.state != .Reject) : ({
            self.shift(tokens, &index);
        }) {
            self.reduce();
        } else {
            if (self.state == .Accept) {
                return self.stack[0];
            } else {
                return error.InvalidInput;
            }
        }
    }

    pub fn reduce(self: Self) !void {
        var reducer_rule, var stack_index = self.grammer.accept(try self.symbols_stack());
        while (reducer_rule) : ({
            reducer_rule, stack_index = self.grammer.accept(try self.symbols_stack());
        }) {
            if (reducer_rule) |rule| {
                try self.stack.insert(@intCast(stack_index), Symbol{ .stype = rule.ntype.to_symbol_type(), .value = .{ .node = try rule.reduce(self.stack[@intCast(stack_index)..]) } });
                try self.stack.shrinkAndFree(@intCast(stack_index + 1));
            }
        }
    }

    pub fn shift(self: Self, tokens: []Token, index: *usize) !void {
        index.* += 1;
        try self.stack.append(Symbol{ .stype = TokenType.to_symbol_type(), .value = .{ .token = tokens[index.*] } });
    }

    pub fn symbols_stack(self: Self) ![]SymbolType {
        var symbols_type_stack = std.ArrayList(SymbolType).init(SymbolType);
        for (self.stack.items) |symbol| {
            try symbols_type_stack.append(symbol.stype);
        }
        return symbols_type_stack.items;
    }
};
