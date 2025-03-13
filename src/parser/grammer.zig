const std = @import("std");
const Allocator = std.mem.Allocator;

const rulem = @import("./rule.zig");
const nodem = @import("./node.zig");
const symbolm = @import("./symbol.zig");

const Rule = rulem.Rule;
const NodeType = nodem.NodeType;
const SymbolType = symbolm.SymbolType;
const Symbol = symbolm.Symbol;

pub const Grammer = struct {
    const Self = @This();
    allocator: Allocator,
    rules: []Rule,
    entry_point: NodeType,

    pub fn init(allocator: Allocator, entry_point: NodeType, rules: []const Rule) Self {
        return Grammer{ .allocator = allocator, .entry_point = entry_point, .rules = @constCast(rules) };
    }

    pub fn accept(self: Self, symbols: []Symbol) struct { ?Rule, i32 } {
        var accepted_rule: ?Rule = null;
        var stack_index: i32 = -1;
        for (symbols, 0..) |_, i| {
            const symbols_slice = symbols[@intCast(symbols.len - 1 - i)..];
            for (self.rules) |rule| {
                if (rule.accept(symbols_slice) and i > stack_index) {
                    accepted_rule = rule;
                    stack_index = @intCast(symbols.len - 1 - i);
                }
            }
        }
        return .{ accepted_rule, stack_index };
    }
};
