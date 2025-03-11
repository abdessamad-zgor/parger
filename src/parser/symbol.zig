const std = @import("std");

const tokenm = @import("./token.zig");
const nodem = @import("./node.zig");

const TokenType = tokenm.TokenType;
const Token = tokenm.Token;
const NodeType = nodem.NodeType;
const Node = nodem.Node;

pub fn MergeEnums(comptime EnumA: type, comptime EnumB: type) type {
    const token_fields = blk: {
        switch (@typeInfo(EnumA)) {
            .Enum => |e| break :blk e.fields,
            else => @compileError(@typeName(EnumA) ++ " must be an enum"),
        }
    };

    const node_fields = blk: {
        switch (@typeInfo(EnumB)) {
            .Enum => |e| break :blk e.fields,
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

    return @Type(.{ .Enum = .{
        .decls = &.{},
        .tag_type = i16,
        .fields = &fields,
        .is_exhaustive = true,
    } });
}

pub const SymbolType = MergeEnums(TokenType, NodeType);

pub const Symbol = struct {
    stype: SymbolType,
    value: union(enum) { token: Token, node: Node },
};
