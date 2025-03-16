const std = @import("std");

const symbolm = @import("./symbol.zig");
const tokenm = @import("./token.zig");

const SymbolType = symbolm.SymbolType;
const Token = tokenm.Token;

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
    FullFlag,
    ArgumentList,
    CommandDef,
    OptionDef,
    Def,
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

pub const Node = struct {
    ntype: NodeType,
    tokens: []Token,
    nodes: []Node,
    index: usize,

    pub fn init(ntype: NodeType, tokens: []Token, nodes: []Node, index: usize) Node {
        return Node{ .ntype = ntype, .tokens = tokens, .nodes = nodes, .index = index };
    }
};
