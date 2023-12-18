const std = @import("std");
const expect = std.testing.expect;

const input = "day05.input";

const Range = struct {
    source_start: usize,
    dest_start: usize,
    length: usize,

    fn dest(self: Range, source: usize) ?usize {
        if (source >= self.source_start and
            source < self.source_start + self.length)
        {
            return self.dest_start + source - self.source_start;
        }
        return null;
    }
};

const Map = struct {
    ranges: std.ArrayList(Range),

    fn init(allocator: std.mem.Allocator) !Map {
        return Map{
            .ranges = std.ArrayList(Range).init(allocator),
        };
    }

    fn deinit(self: *Map) void {
        self.ranges.deinit();
    }

    fn dest(self: *Map, source: usize) usize {
        for (self.ranges.items) |r| {
            if (r.dest(source)) |t| return t;
        }
        return source;
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

    // List of seeds
    var seeds = std.ArrayList(usize).init(allocator);
    try reader.streamUntilDelimiter(line.writer(), '\n', null);
    var it = std.mem.splitAny(u8, line.items, ":");
    _ = it.first();

    var seeds_it = std.mem.splitAny(u8, std.mem.trim(u8, it.rest(), " "), " ");
    while (seeds_it.next()) |s| {
        const seed = std.fmt.parseInt(usize, s, 10) catch continue;
        try seeds.append(seed);
    }

    // List of maps
    var map_list = std.ArrayList(Map).init(allocator);
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
        if (std.fmt.parseInt(usize, s.?, 10)) |dest| {
            var r = Range{
                .dest_start = dest,
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
            cur_map = try Map.init(allocator);
        }
        line.clearRetainingCapacity();
    }

    // For each seed, map to location via list of maps
    var lowest_location: ?usize = null;
    for (seeds.items) |seed| {
        var x = seed;
        for (map_list.items) |m| {
            var map = m;
            x = map.dest(x);
        }
        if (lowest_location == null or x < lowest_location.?) {
            lowest_location = x;
        }
    }

    std.debug.print("partOne: lowest_location={any}\n", .{lowest_location});
}

fn partTwo(base_allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(allocator);
    var reader = file.reader();

    // List of ranges of seeds
    var seeds = std.ArrayList([2]usize).init(allocator);
    try reader.streamUntilDelimiter(line.writer(), '\n', null);
    var it = std.mem.splitAny(u8, line.items, ":");
    _ = it.first();

    var seeds_it = std.mem.splitAny(u8, std.mem.trim(u8, it.rest(), " "), " ");
    while (seeds_it.next()) |s| {
        const start = std.fmt.parseInt(usize, s, 10) catch continue;
        const length = std.fmt.parseInt(usize, seeds_it.next().?, 10) catch continue;
        try seeds.append([2]usize{ start, length });
    }

    // List of maps
    var map_list = std.ArrayList(Map).init(allocator);
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
        if (std.fmt.parseInt(usize, s.?, 10)) |dest| {
            var r = Range{
                .dest_start = dest,
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
            cur_map = try Map.init(allocator);
        }
        line.clearRetainingCapacity();
    }

    // Brute force solution.
    // Spawn thread for each seed range, map to location via list of maps
    var threads: []std.Thread = try allocator.alloc(std.Thread, seeds.items.len);
    var lowest_locations: []usize = try allocator.alloc(usize, seeds.items.len);
    @memset(lowest_locations, std.math.maxInt(usize));
    for (seeds.items, 0..) |seed_range, i| {
        threads[i] = try std.Thread.spawn(
            .{},
            struct {
                fn location(
                    srange: [2]usize,
                    mlist: std.ArrayList(Map),
                    lowest: *usize,
                ) void {
                    for (0..srange[1]) |j| {
                        var x = srange[0] + j;
                        for (mlist.items) |m| {
                            var map = m;
                            x = map.dest(x);
                        }
                        if (x < lowest.*) lowest.* = x;
                    }
                }
            }.location,
            .{ seed_range, map_list, &lowest_locations[i] },
        );
        std.debug.print("thread: {any}\n", .{seed_range});
    }
    for (threads) |t| t.join();

    const lowest = std.mem.min(usize, lowest_locations);
    std.debug.print("partTwo: lowest_location={any}\n", .{lowest});
}

test "partOne" {
    try partOne(std.testing.allocator);
}

test "partTwo" {
    try partTwo(std.testing.allocator);
}
