const std = @import("std");
const Allocator = std.mem.Allocator;

const Action = fn (option_values: []OptionValue(type)) void;

const Argument = struct { required: bool, order: u8, name: []u8 };

const Command = struct { name: []u8, description: []u8, options: ?[]Option, action: ?Action, arguments: ?[]Argument };

const OptionType = enum { Any, Choices, Typed, Boolean };

fn OptionValue(comptime t: type) type {
    return struct { label: []u8, value: t };
}

const OptionTypeUnion = union(OptionType) { Any: void, Choices: [][]u8, Typed: type, Boolean: void };

const Option = struct { short: u8, long: []u8, details: OptionTypeUnion };

/// Because this use case is fairly simple we would like it to fail on error to allow 
/// for chain method calling

const Parger = struct {
    const Self = @This();
    default: ?Command,
    commands: std.ArrayList(Command),
    allocator: Allocator,

    fn init(allocator: Allocator) Self {
        return Parger{ .allocator = allocator, .default = null, .commands = std.ArrayList(Command).init(allocator) };
    }

    fn deinit(self: Self) void {
        self.allocator.free(self);
    }

    fn command(self: Self, command_name: []u8, description: []u8) *Command {
        const new_command = self.allocator.alloc(Command, 1) catch |err| {
            std.log.err("Allocation Error: failed to allocate new command {}", .{err});
            std.process.exit(1);
        };
        @memcpy(new_command, &[_]Command{Command{.name = command_name, .description = description, .arguments = null, .options = null, .action = null}});
        self.commands.appendSlice(new_command) catch |err| {
            std.log.err("Allocation Error: failed to allocate new command on Parger.commands {}", .{err});
            std.process.exit(1);
        };
        return &new_command[0];
    }



    fn option(self: Self, option_string: []u8) *Command {
        if (self.default == null) {
            self.default = Command{.name = "", .description = "", .options = &[_]Option{Option{.short = short, .long = }}}
        }
        if (choices != null) {
            const opt_choices = choices.?;
        }
    } 
};
