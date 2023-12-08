const std = @import("std");
const expect = std.testing.expect;

const input = "day01.input";

fn partOne(base_allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(allocator);
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

fn partTwo(base_allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var trie = try initTrie(allocator);
    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(allocator);
    var sum: u32 = 0;
    var reader = file.reader();
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

fn initTrie(allocator: std.mem.Allocator) !Trie {
    var trie = Trie.init(allocator);
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

test "partOne" {
    try partOne(std.testing.allocator);
}

test "partTwo" {
    try partTwo(std.testing.allocator);
}

pub const Trie = struct {
    allocator: std.mem.Allocator,
    root: TrieNode,

    pub fn init(allocator: std.mem.Allocator) Trie {
        var root = TrieNode{
            .children = std.AutoHashMap(u8, TrieNode).init(allocator),
            .value = null,
        };
        return Trie{
            .allocator = allocator,
            .root = root,
        };
    }

    pub fn deinit(self: *Trie) void {
        self.root.deinit();
    }

    pub fn insert(self: *Trie, key: []const u8, value: u8) !void {
        var node = &self.root;
        for (key) |c| {
            var v = try node.children.getOrPut(c);
            if (!v.found_existing) {
                v.value_ptr.* = TrieNode{
                    .children = std.AutoHashMap(u8, TrieNode).init(self.allocator),
                    .value = null,
                };
            }
            node = v.value_ptr;
        }
        node.value = value;
    }

    pub fn find(self: Trie, key: []const u8) !?u8 {
        var node = self.root;
        for (key) |c| {
            if (node.children.get(c)) |child| {
                node = child;
            } else {
                return null;
            }
        }
        return node.value;
    }
};

const TrieNode = struct {
    children: std.AutoHashMap(u8, TrieNode),
    value: ?u8,

    pub fn deinit(self: *TrieNode) void {
        var iter = self.children.valueIterator();
        while (iter.next()) |child| {
            child.deinit();
        }
        self.children.deinit();
    }
};

test "trie" {
    var trie = Trie.init(std.testing.allocator);
    defer trie.deinit();

    try trie.insert("one", 1);
    try trie.insert("two", 2);
    try trie.insert("three", 3);
    try trie.insert("onee", 11);

    try expect(try trie.find("one") == 1);
    try expect(try trie.find("two") == 2);
    try expect(try trie.find("three") == 3);
    try expect(try trie.find("three") != 1);
    try expect(try trie.find("onee") == 11);
    try expect(try trie.find("four") == null);
}
