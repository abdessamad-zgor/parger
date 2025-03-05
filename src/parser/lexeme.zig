pub const LexemeType = enum {
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

pub const Lexeme = union(LexemeType) {
    const Self = @This();
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

    pub fn to_char(self: Self) u8 {
        return switch (self) {
            .dash => '-',
            .literal => |char| char,
            .dot => '.',
            .lbrace => '[',
            .rbrace => ']',
            .gt => '>',
            .lt => '<',
            .comma => ',',
            .space => ' ',
            .equals => '=',
        };
    }
};
