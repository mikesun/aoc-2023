const std = @import("std");

const input = "day04.input";
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn partOne() !void {
    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(gpa.allocator());
    defer line.deinit();

    var points: u32 = 0;
    var reader = file.reader();
    while (true) {
        reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        var line_it = std.mem.splitAny(u8, line.items, ":");
        _ = line_it.first();
        var sets_it = std.mem.splitAny(u8, line_it.rest(), "|");

        // Winning numbers
        var winning = std.AutoHashMap(u32, bool).init(gpa.allocator());
        defer winning.deinit();
        var w_it = std.mem.split(u8, std.mem.trim(u8, sets_it.first(), " "), " ");
        while (w_it.next()) |n| {
            const win = std.fmt.parseInt(u32, n, 10) catch continue;
            try winning.put(win, true);
        }

        // My numbers
        var win_count: u32 = 0;
        var n_it = std.mem.split(u8, std.mem.trim(u8, sets_it.rest(), " "), " ");
        while (n_it.next()) |n| {
            var num = std.fmt.parseInt(u32, n, 10) catch continue;
            if (winning.contains(num)) win_count += 1;
        }

        if (win_count > 0) points += std.math.pow(u32, 2, win_count - 1);
        line.clearRetainingCapacity();
    }
    std.debug.print("points={d}\n", .{points});
}

fn partTwo() !void {
    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(gpa.allocator());
    defer line.deinit();
    var reader = file.reader();

    // Map of card_id:wins
    var cards_wins = std.AutoHashMap(u32, u32).init(gpa.allocator());
    defer cards_wins.deinit();

    // Map of cards:processed_count
    var cards_processed = std.AutoHashMap(u32, u32).init(gpa.allocator());

    // List of cards to be processed
    var copies_to_process = std.ArrayList(u32).init(gpa.allocator());
    defer copies_to_process.deinit();

    // Process original cards
    while (true) {
        reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        var line_it = std.mem.splitAny(u8, line.items, ":");

        // Card ID
        var card_it = std.mem.splitAny(u8, line_it.first(), " ");
        _ = card_it.first();
        const card_id = try std.fmt.parseInt(u32, std.mem.trim(u8, card_it.rest(), " "), 10);

        var sets_it = std.mem.splitAny(u8, line_it.rest(), "|");

        // Winning numbers
        var winning = std.AutoHashMap(u32, bool).init(gpa.allocator());
        defer winning.deinit();
        var w_it = std.mem.split(u8, std.mem.trim(u8, sets_it.first(), " "), " ");
        while (w_it.next()) |n| {
            const win = std.fmt.parseInt(u32, n, 10) catch continue;
            try winning.put(win, true);
        }

        // My numbers
        var wins: u32 = 0;
        var n_it = std.mem.split(u8, std.mem.trim(u8, sets_it.rest(), " "), " ");
        while (n_it.next()) |n| {
            var num = std.fmt.parseInt(u32, n, 10) catch continue;
            if (winning.contains(num)) wins += 1;
        }

        // Add to cards-wins map
        try cards_wins.put(card_id, wins);

        // Add copies_to_process list
        for (1..wins + 1) |i| {
            const copy_card_id = card_id + @as(u32, @intCast(i));
            try copies_to_process.append(copy_card_id);
        }

        // Update card in processed map
        try cards_processed.put(card_id, (cards_processed.get(card_id) orelse 0) + 1);

        line.clearRetainingCapacity();
    }

    // Process card copies
    while (copies_to_process.popOrNull()) |card_id| {
        const wins = cards_wins.get(card_id) orelse continue;
        for (1..wins + 1) |i| {
            try copies_to_process.append(card_id + @as(u32, @intCast(i)));
        }
        try cards_processed.put(card_id, (cards_processed.get(card_id) orelse 0) + 1);
    }

    // Count cards processed
    var cards_count: u32 = 0;
    var counts_it = cards_processed.valueIterator();
    while (counts_it.next()) |c| cards_count += c.*;
    std.debug.print("cards processed={d}\n", .{cards_count});
}

pub fn main() !void {
    try partOne();
    try partTwo();
}
