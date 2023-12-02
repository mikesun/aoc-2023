const std = @import("std");

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

const expect = std.testing.expect;

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
