const std = @import("std");

const input = "day06.input";

fn partOne(base_allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();
    var reader = file.reader();

    var doc = [2]std.ArrayList(usize){ undefined, undefined };
    for (0..2) |i| {
        var line = std.ArrayList(u8).init(allocator);
        try reader.streamUntilDelimiter(line.writer(), '\n', null);

        var it = std.mem.splitAny(u8, try line.toOwnedSlice(), ":");
        _ = it.first();

        var nums_it = std.mem.splitAny(u8, std.mem.trim(u8, it.rest(), " "), " ");
        doc[i] = std.ArrayList(usize).init(allocator);
        while (nums_it.next()) |n| {
            var num = std.fmt.parseInt(usize, std.mem.trim(u8, n, " "), 10) catch continue;
            try doc[i].append(num);
        }
    }

    const times = try doc[0].toOwnedSlice();
    const records = try doc[1].toOwnedSlice();
    var product: usize = 1;

    for (times, records) |t, r| {
        var ways: usize = 0;
        for (0..t + 1) |speed| {
            const d = distance(t, speed);
            if (d > r) ways += 1;
        }
        product *= ways;
    }
    std.debug.print("part_one product={}\n", .{product});
}

fn distance(time: usize, speed: usize) usize {
    return (time - speed) * speed;
}

fn partTwo(base_allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();
    var reader = file.reader();

    var doc = [2]std.ArrayList(u8){ undefined, undefined };
    for (0..2) |i| {
        var line = std.ArrayList(u8).init(allocator);
        try reader.streamUntilDelimiter(line.writer(), '\n', null);

        var it = std.mem.splitAny(u8, try line.toOwnedSlice(), ":");
        _ = it.first();

        var nums_it = std.mem.splitAny(u8, std.mem.trim(u8, it.rest(), " "), " ");
        doc[i] = std.ArrayList(u8).init(allocator);
        while (nums_it.next()) |n| {
            const num = std.mem.trim(u8, n, " ");
            if (num.len > 0) try doc[i].appendSlice(num);
        }
    }

    const time = try std.fmt.parseInt(usize, try doc[0].toOwnedSlice(), 10);
    const record = try std.fmt.parseInt(usize, try doc[1].toOwnedSlice(), 10);
    var ways: usize = 0;
    for (0..time + 1) |speed| {
        const d = distance(time, speed);
        if (d > record) ways += 1;
    }
    std.debug.print("part_two ways={}\n", .{ways});
}

test "partOne" {
    try partOne(std.testing.allocator);
}

test "partTwo" {
    try partTwo(std.testing.allocator);
}
