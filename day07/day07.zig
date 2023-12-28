const std = @import("std");

const print = std.debug.print;
const expect = std.testing.expect;

const input = "test.input";

const HandType = enum {
    five_of_a_kind,
    four_of_a_kind,
    full_house,
    three_of_a_kind,
    two_pair,
    one_pair,
    high_card,
};

const Hand = struct {
    cards: []const u8,
    bid: u32,
    type: HandType,

    pub fn lessThan(_: void, a: Hand, b: Hand) bool {
        return a.bid < b.bid;
    }
};

fn partOne(base_allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(allocator);
    var reader = file.reader();

    // Parse list of hands
    var unsorted_hands = std.ArrayList(Hand).init(allocator);
    while (true) {
        reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        defer line.clearRetainingCapacity();

        // Hand
        var it = std.mem.splitAny(u8, line.items, " ");
        const h = Hand{
            .cards = it.first(),
            .bid = try std.fmt.parseInt(u32, it.rest(), 10),
        };
        try unsorted_hands.append(h);
    }

    // Sort hands
    const hands = try unsorted_hands.toOwnedSlice();
    std.mem.sort(Hand, hands, {}, Hand.lessThan);
    print("{any}\n", .{hands});
}

test "partOne" {
    try partOne(std.testing.allocator);
}

// test "partTwo" {
//     try partTwo(std.testing.allocator);
// }
