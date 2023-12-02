const std = @import("std");
const Trie = @import("trie.zig").Trie;

const input = "day01.input";
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn partOne() !void {
    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(gpa.allocator());
    defer line.deinit();

    var sum: u32 = 0;
    var reader = file.reader();
    while (true) {
        reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        var first: ?u8 = null;
        var last: ?u8 = null;

        for (line.items) |c| {
            if (std.ascii.isDigit(c)) {
                first = first orelse c - 48;
                last = c - 48;
            }
        }
        sum += first.? * 10 + last.?;
        line.clearRetainingCapacity();
    }
    std.debug.print("part one sum={}\n", .{sum});
}

fn partTwo() !void {
    var trie = try initTrie();
    defer trie.deinit();

    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(gpa.allocator());
    defer line.deinit();

    var sum: u32 = 0;
    var reader = file.reader();

    // Read line-by-line
    while (true) {
        reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        var chars = line.items;
        var first: ?u8 = null;
        var last: ?u8 = null;

        for (chars, 0..) |c, i| {
            if (std.ascii.isDigit(c)) {
                first = first orelse c - 48;
                last = c - 48;
            } else {
                // Check if substrings beginning with current character is in trie
                // Note: 'twone' should be interpreted as '21'
                for (i..chars.len + 1) |j| {
                    if (try trie.find(chars[i..j])) |v| {
                        first = first orelse v;
                        last = v;
                    }
                }
            }
        }
        sum += first.? * 10 + last.?;
        line.clearRetainingCapacity();
    }
    std.debug.print("part two sum={}\n", .{sum});
}

fn initTrie() !Trie {
    var trie = Trie.init(gpa.allocator());
    try trie.insert("one", 1);
    try trie.insert("two", 2);
    try trie.insert("three", 3);
    try trie.insert("four", 4);
    try trie.insert("five", 5);
    try trie.insert("six", 6);
    try trie.insert("seven", 7);
    try trie.insert("eight", 8);
    try trie.insert("nine", 9);
    return trie;
}

pub fn main() !void {
    try partOne();
    try partTwo();
}
