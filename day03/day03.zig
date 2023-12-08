const std = @import("std");

const input = "day03.input";

fn partOne(base_allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();
    var reader = file.reader();

    // Read file
    var lines = std.ArrayList([]u8).init(allocator);
    while (true) {
        var row = std.ArrayList(u8).init(allocator);
        reader.streamUntilDelimiter(row.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        try lines.append(try row.toOwnedSlice());
    }

    var sum: u32 = 0;
    var schematic: [][]u8 = try lines.toOwnedSlice();
    for (schematic, 0..) |cur, i| {
        var start: ?usize = null;
        for (cur, 0..) |c, j| {
            if (!std.ascii.isDigit(c)) continue;

            // Start of number string
            if (start == null and std.ascii.isDigit(c)) start = j;

            // Additional digits in number string
            const next_digit: ?u8 = if (j + 1 < cur.len) cur[j + 1] else null;
            if (next_digit != null and std.ascii.isDigit(next_digit.?)) {
                continue;
            }

            // Last digit of number string
            const number = try std.fmt.parseInt(u32, cur[start.? .. j + 1], 10);
            check: {
                // check for symbol at cur_row.start-1
                if (start.? > 0 and cur[start.? - 1] != '.') {
                    sum += number;
                    break :check;
                }

                // check for symbol at cur_row.end+1
                if (j + 1 < cur.len and cur[j + 1] != '.') {
                    sum += number;
                    break :check;
                }

                // Check for symbol in range of (prev, start-1) to (prev. end+1)
                if (i > 0) {
                    const prev = schematic[i - 1];
                    const prev_start = if (start.? > 0) start.? - 1 else start.?;
                    const prev_end = if (j + 1 < prev.len) j + 1 else j;
                    for (prev_start..prev_end + 1) |z| {
                        if (prev[z] != '.' and !std.ascii.isDigit(prev[z])) {
                            sum += number;
                            break :check;
                        }
                    }
                }

                // Check for symbol at in range of (next, start-1) to (next, end+1)
                if (i + 1 < schematic.len) {
                    const next = schematic[i + 1];
                    const next_start = if (start.? > 0) start.? - 1 else start.?;
                    const next_end = if (j + 1 < next.len) j + 1 else j;
                    for (next_start..next_end + 1) |z| {
                        if (next[z] != '.' and !std.ascii.isDigit(next[z])) {
                            sum += number;
                            break :check;
                        }
                    }
                }
            }
            start = null;
        }
    }

    std.debug.print("sum={}\n", .{sum});
}

fn partTwo(base_allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();
    var reader = file.reader();

    // Read file
    var lines = std.ArrayList([]u8).init(allocator);
    while (true) {
        var row = std.ArrayList(u8).init(allocator);
        reader.streamUntilDelimiter(row.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        try lines.append(try row.toOwnedSlice());
    }
    var schematic: [][]u8 = try lines.toOwnedSlice();

    // Build part numbers map
    var numberMap = std.AutoHashMap([2]usize, u32).init(allocator);
    defer numberMap.deinit();
    for (schematic, 0..) |cur, i| {
        var start: ?usize = null;
        for (cur, 0..) |c, j| {
            if (!std.ascii.isDigit(c)) continue;

            // start of number substring
            if (start == null and std.ascii.isDigit(c)) start = j;

            // more digits in number substring
            const next_digit: ?u8 = if (j + 1 < cur.len) cur[j + 1] else null;
            if (next_digit != null and std.ascii.isDigit(next_digit.?)) {
                continue;
            }

            // end of number substring
            const number = try std.fmt.parseInt(u32, cur[start.? .. j + 1], 10);

            for (start.?..j + 1) |z| {
                try numberMap.put([2]usize{ i, z }, number);
            }

            start = null;
        }
    }

    // Find gear ratios
    var gear_ratio_sum: u32 = 0;
    for (schematic, 0..) |cur, i| {
        for (cur, 0..) |c, j| {
            if (c != '*') continue;

            var adjacent_count: u32 = 0;
            var gear_ratio: u32 = 1;

            // Check for digit at (cur, j-1)
            if (j > 0 and std.ascii.isDigit(cur[j - 1])) {
                adjacent_count += 1;
                gear_ratio *= numberMap.get([2]usize{ i, j - 1 }).?;
            }

            // Check for digit at (cur, j+1)
            if (j + 1 < cur.len and std.ascii.isDigit(cur[j + 1])) {
                adjacent_count += 1;
                gear_ratio *= numberMap.get([2]usize{ i, j + 1 }).?;
            }

            // Check for digits from (prev, j-1) to (prev, j+1)
            if (i > 0) {
                const prev = schematic[i - 1];
                const prev_start = if (j > 0) j - 1 else j;
                const prev_end = if (j + 1 < prev.len) j + 1 else j;
                var prev_adj_num: ?u32 = null;
                for (prev_start..prev_end + 1) |z| {
                    if (std.ascii.isDigit(prev[z])) {
                        const adj_num = numberMap.get([2]usize{ i - 1, z }).?;

                        // Check for different part number
                        if (prev_adj_num == null or (prev_adj_num != adj_num)) {
                            adjacent_count += 1;
                            gear_ratio *= adj_num;
                            prev_adj_num = adj_num;
                        }
                    }
                }
            }

            // Check for digits from (next, j-1) to (next, j+1)
            if (i + 1 < schematic.len) {
                const next = schematic[i + 1];
                const next_start = if (j > 0) j - 1 else j;
                const next_end = if (j + 1 < next.len) j + 1 else j;
                var prev_adj_num: ?u32 = null;
                for (next_start..next_end + 1) |z| {
                    if (std.ascii.isDigit(next[z])) {
                        const adj_num = numberMap.get([2]usize{ i + 1, z }).?;

                        // Check for different part number
                        if (prev_adj_num == null or prev_adj_num != adj_num) {
                            adjacent_count += 1;
                            gear_ratio *= adj_num;
                            prev_adj_num = adj_num;
                        }
                    }
                }
            }

            // Check if exactly two adjacent numbers
            if (adjacent_count == 2) {
                gear_ratio_sum += gear_ratio;
            }
        }
    }

    std.debug.print("gear_ratio_sum={d}\n", .{gear_ratio_sum});
}

test "partOne" {
    try partOne(std.testing.allocator);
}

test "partTwo" {
    try partTwo(std.testing.allocator);
}
