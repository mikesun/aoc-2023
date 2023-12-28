const std = @import("std");

const print = std.debug.print;
const expect = std.testing.expect;

const input = "test.input";

const Hand = struct {
    cards: []const u8,
    bid: u32,
};

fn partOne(base_allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(allocator);
    var reader = file.reader();

    var hands = std.ArrayList(Hand).init(allocator);
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
        try hands.append(h);
        print("{any}\n", .{h});
    }
}

test "partOne" {
    try partOne(std.testing.allocator);
}

// test "partTwo" {
//     try partTwo(std.testing.allocator);
// }
