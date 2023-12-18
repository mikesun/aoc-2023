const std = @import("std");

const print = std.debug.print;
const expect = std.testing.expect;

const input_file = "day05.input";

const Range = struct {
    start: usize,
    end: usize,

    fn init(allocator: std.mem.Allocator, start: usize, end: usize) !Range {
        var r = try allocator.create(Range);
        r.start = start;
        r.end = end;
        return r.*;
    }
};

const MapRange = struct {
    source_start: usize,
    dest_start: usize,
    length: usize,
};

const Map = struct {
    allocator: std.mem.Allocator,
    map_ranges: std.ArrayList(MapRange),

    fn init(allocator: std.mem.Allocator) !Map {
        var m = try allocator.create(Map);
        m.allocator = allocator;
        m.map_ranges = std.ArrayList(MapRange).init(allocator);
        return m.*;
    }

    fn destRanges(self: Map, input_ranges: std.ArrayList(Range)) !std.ArrayList(Range) {
        var inputs = input_ranges;
        var outputs = std.ArrayList(Range).init(self.allocator);

        // Input ranges
        inputs: while (inputs.popOrNull()) |input| {
            // Map ranges
            for (self.map_ranges.items) |mrange| {
                const source_start = mrange.source_start;
                const source_end = mrange.source_start + mrange.length;
                const dest_start = mrange.dest_start;

                // Input range not intersected by map source range
                if (source_end <= input.start or input.end <= source_start) continue;

                // Input range begins with subsequence mapped by source range
                if (source_start <= input.start) {
                    const start = input.start;
                    const end = if (source_end <= input.end) source_end else input.end;

                    // Add mapped destination range to outputs
                    var out = try self.allocator.create(Range);
                    out.start = dest_start + (start - source_start);
                    out.end = dest_start + (end - source_start);
                    try outputs.append(out.*);

                    // Append any unmapped portion of input
                    if (end < input.end) {
                        try inputs.append(try Range.init(self.allocator, end, input.end));
                    }
                    continue :inputs;
                }
                // Input range begins with subsequence not mapped by source range, split.
                else {
                    try inputs.append(try Range.init(self.allocator, input.start, source_start));
                    try inputs.append(try Range.init(self.allocator, source_start, input.end));
                    continue :inputs;
                }
            }
            // Input range does not have any mappings
            try outputs.append(input);
        }
        return outputs;
    }
};

fn partTwo(base_allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(allocator);
    var reader = file.reader();

    // List of ranges of seeds
    var seed_ranges = std.ArrayList(Range).init(allocator);
    {
        try reader.streamUntilDelimiter(line.writer(), '\n', null);
        var it = std.mem.splitAny(u8, line.items, ":");
        _ = it.first();

        var seeds_it = std.mem.splitAny(u8, std.mem.trim(u8, it.rest(), " "), " ");
        while (seeds_it.next()) |s| {
            const start = std.fmt.parseInt(usize, s, 10) catch continue;
            const length = std.fmt.parseInt(usize, seeds_it.next().?, 10) catch continue;
            try seed_ranges.append(Range{
                .start = start,
                .end = start + length,
            });
        }
        line.clearRetainingCapacity();
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
            var r = MapRange{
                .dest_start = dest,
                .source_start = undefined,
                .length = undefined,
            };
            s = line_it.next();
            r.source_start = try std.fmt.parseInt(usize, s.?, 10);
            s = line_it.next();
            r.length = try std.fmt.parseInt(usize, s.?, 10);
            try cur_map.?.map_ranges.append(r);
        }
        // Map name
        else |err| {
            _ = err catch {};
            if (cur_map) |m| try map_list.append(m);
            cur_map = try Map.init(allocator);
        }
        line.clearRetainingCapacity();
    }

    // For list of seed ranges, iteratively map to to list of location ranges
    var ranges = seed_ranges;
    for (map_list.items) |*m| ranges = try m.destRanges(ranges);

    // Get lowest starting location across all location ranges
    var lowest_location: usize = std.math.maxInt(usize);
    for (ranges.items) |r| {
        if (r.start < lowest_location) lowest_location = r.start;
    }

    print("partTwo: lowest_location={d}\n", .{lowest_location});
}

test "partTwo" {
    try partTwo(std.testing.allocator);
}
