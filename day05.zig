const std = @import("std");
const expect = std.testing.expect;

const input = "day05.input";
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const Range = struct {
    source_start: usize,
    target_start: usize,
    length: usize,

    fn target(self: Range, source: usize) ?usize {
        if (source >= self.source_start and
            source < self.source_start + self.length)
        {
            return self.target_start + source - self.source_start;
        }
        return null;
    }
};

test "range" {
    const r = Range{
        .source_start = 98,
        .target_start = 50,
        .length = 2,
    };
    const source = 98;
    const target = r.target(source);
    try expect(target.? == 50);
}

const Map = struct {
    ranges: std.ArrayList(Range),

    fn init(allocator: std.mem.Allocator) !Map {
        return Map{
            .ranges = std.ArrayList(Range).init(allocator),
        };
    }

    fn target(self: *Map, source: usize) usize {
        for (self.ranges.items) |r| {
            if (r.target(source)) |t| return t;
        }
        return source;
    }
};

fn partOne() !void {
    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(gpa.allocator());
    defer line.deinit();
    var reader = file.reader();

    // List of seeds
    var seeds = std.ArrayList(usize).init(gpa.allocator());
    defer seeds.deinit();
    try reader.streamUntilDelimiter(line.writer(), '\n', null);
    var it = std.mem.splitAny(u8, try line.toOwnedSlice(), ":");
    _ = it.first();

    var seeds_it = std.mem.splitAny(u8, std.mem.trim(u8, it.rest(), " "), " ");
    while (seeds_it.next()) |s| {
        var seed = std.fmt.parseInt(usize, s, 10) catch continue;
        try seeds.append(seed);
    }

    // List of maps
    var map_list = std.ArrayList(Map).init(gpa.allocator());
    defer map_list.deinit();
    var cur_map: ?Map = null;
    while (true) {
        reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => {
                if (cur_map) |m| try map_list.append(m);
                break;
            },
            else => return err,
        };

        // Blank line
        if (line.items.len == 0) continue;

        var line_it = std.mem.splitAny(u8, line.items, " ");
        var s = line_it.next();

        // Range
        if (std.fmt.parseInt(usize, s.?, 10)) |target| {
            var r = Range{
                .target_start = target,
                .source_start = undefined,
                .length = undefined,
            };
            s = line_it.next();
            r.source_start = try std.fmt.parseInt(usize, s.?, 10);
            s = line_it.next();
            r.length = try std.fmt.parseInt(usize, s.?, 10);
            try cur_map.?.ranges.append(r);
        }
        // Map name
        else |err| {
            _ = err catch {};
            if (cur_map) |m| try map_list.append(m);
            cur_map = try Map.init(gpa.allocator());
        }
        line.clearRetainingCapacity();
    }

    // For each seed, map to location via list of maps
    var lowest_location: ?usize = null;
    for (seeds.items) |seed| {
        var x = seed;
        for (map_list.items) |m| {
            var map = m;
            x = map.target(x);
        }
        if (lowest_location == null or x < lowest_location.?) {
            lowest_location = x;
        }
    }
    std.debug.print("partOne: lowest_location={any}\n", .{lowest_location});
}

fn partTwo() !void {
    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(gpa.allocator());
    defer line.deinit();
    var reader = file.reader();

    // List of ranges of seeds
    var seeds = std.ArrayList([2]usize).init(gpa.allocator());
    defer seeds.deinit();
    try reader.streamUntilDelimiter(line.writer(), '\n', null);
    var it = std.mem.splitAny(u8, try line.toOwnedSlice(), ":");
    _ = it.first();

    var seeds_it = std.mem.splitAny(u8, std.mem.trim(u8, it.rest(), " "), " ");
    while (seeds_it.next()) |s| {
        var start = std.fmt.parseInt(usize, s, 10) catch continue;
        var length = std.fmt.parseInt(usize, seeds_it.next().?, 10) catch continue;
        try seeds.append([2]usize{ start, length });
    }

    // List of maps
    var map_list = std.ArrayList(Map).init(gpa.allocator());
    defer map_list.deinit();
    var cur_map: ?Map = null;
    while (true) {
        reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => {
                if (cur_map) |m| try map_list.append(m);
                break;
            },
            else => return err,
        };

        // Blank line
        if (line.items.len == 0) continue;

        var line_it = std.mem.splitAny(u8, line.items, " ");
        var s = line_it.next();

        // Range
        if (std.fmt.parseInt(usize, s.?, 10)) |target| {
            var r = Range{
                .target_start = target,
                .source_start = undefined,
                .length = undefined,
            };
            s = line_it.next();
            r.source_start = try std.fmt.parseInt(usize, s.?, 10);
            s = line_it.next();
            r.length = try std.fmt.parseInt(usize, s.?, 10);
            try cur_map.?.ranges.append(r);
        }
        // Map name
        else |err| {
            _ = err catch {};
            if (cur_map) |m| try map_list.append(m);
            cur_map = try Map.init(gpa.allocator());
        }
        line.clearRetainingCapacity();
    }

    // For each seed, map to location via list of maps
    var lowest_location: ?usize = null;
    for (seeds.items) |seed_range| {
        std.debug.print("seed_range={any}\n", .{seed_range});
        for (0..seed_range[1]) |i| {
            var x = seed_range[0] + i;
            for (map_list.items) |m| {
                var map = m;
                x = map.target(x);
            }
            if (lowest_location == null or x < lowest_location.?) {
                lowest_location = x;
            }
        }
    }
    std.debug.print("partTwo: lowest_location={any}\n", .{lowest_location});
}

pub fn main() !void {
    try partOne();
    try partTwo();
}
