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
    symbols: []SymbolType,

    pub fn init(ntype: NodeType, symbols: []const SymbolType) Self {
        return Rule{ .ntype = ntype, .symbols = @constCast(symbols) };
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

    pub fn reduce(self: Self, allocator: Allocator, symbol_stack: []SymbolType, stack: []Symbol, index: usize) !Node {
        if (!self.accept(symbol_stack)) {
            return error.InvalidSymbolStack;
        }
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
