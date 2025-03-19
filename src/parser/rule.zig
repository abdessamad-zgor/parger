const std = @import("std");
const Allocator = std.mem.Allocator;

const tokenm = @import("./token.zig");
const nodem = @import("./node.zig");
const symbolm = @import("./symbol.zig");

const TokenType = tokenm.TokenType;
const Token = tokenm.Token;
const NodeType = nodem.NodeType;
const Node = nodem.Node;
const SymbolType = symbolm.SymbolType;
const Symbol = symbolm.Symbol;

pub const Rule = struct {
    const Self = @This();
    ntype: NodeType,
    variants: [][]SymbolType,

    pub fn init(ntype: NodeType, symbols: [][]SymbolType) Self {
        return Rule{ .ntype = ntype, .variants = @constCast(symbols) };
    }

    pub fn accepts(self: Self, stack: []SymbolType) ParserState {

    }

    pub fn reduce(self: Self, allocator: Allocator, stack: []Symbol, index: usize) !Node {
        const tokens = blk: {
            var tokens_arr = std.ArrayList(Token).init(allocator);
            for (stack) |symbol| {
                switch (symbol.value) {
                    .token => |token| try tokens_arr.append(token),
                    else => continue,
                }
            }
            break :blk tokens_arr.items;
        };
        const nodes = blk: {
            var nodes_arr = std.ArrayList(Node).init(allocator);
            for (stack) |symbol| {
                switch (symbol.value) {
                    .node => |node| try nodes_arr.append(node),
                    else => continue,
                }
            }
            break :blk nodes_arr.items;
        };
        const reduced_node = Node.init(self.ntype, tokens, nodes, index);
        return reduced_node;
    }
};
