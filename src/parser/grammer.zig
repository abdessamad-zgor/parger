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

    pub fn init(allocator: Allocator, entry_point: NodeType, rules: []struct { NodeType, []const []const SymbolType }) !Self {
        var _rules = std.ArrayList(Rule).init(allocator);
        for (rules) |rule| {
            try _rules.append(Rule.init(rule[0], rule[1]));
        }
        return Grammer{ .allocator = allocator, .entry_point = entry_point, .rules = _rules.items };
    }

    pub fn reduce(self: Self, symbols: []Symbol) !struct { ?Rule, usize } {
        var accepted_rule: ?Rule = null;
        var stack_index: usize = 0;
        for (symbols, 0..) |_, i| {
            const symbols_slice = symbols[@intCast(symbols.len - 1 - i)..];
            for (self.rules) |rule| {
                if (rule.accepts(symbols_slice) and i > stack_index) {
                    accepted_rule = rule;
                    stack_index = @intCast(symbols.len - 1 - i);
                }
            }
        }
        return .{ accepted_rule, stack_index };
    }
};
