const std = @import("std");

const input = "day02.input";
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn partOne() !void {
    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(gpa.allocator());
    defer line.deinit();

    var possible_id_sum: u32 = 0;

    var reader = file.reader();
    while (true) {
        reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        var line_it = std.mem.splitAny(u8, line.items, ":");

        // Game ID
        var id_it = std.mem.splitAny(u8, line_it.first(), " ");
        var game_id: u32 = undefined;
        while (id_it.next()) |x| game_id = std.fmt.parseInt(u32, x, 10) catch undefined;

        // Game sets
        game: {
            var sets_it = std.mem.splitAny(u8, line_it.rest(), ";");
            while (sets_it.next()) |set| {
                var balls_it = std.mem.splitAny(u8, set, ",");
                while (balls_it.next()) |ball| {
                    var b_it = std.mem.splitAny(u8, std.mem.trim(u8, ball, " "), " ");
                    var count = try std.fmt.parseInt(u32, b_it.first(), 10);
                    var color = b_it.rest();
                    if ((std.mem.eql(u8, color, "red") and count > 12) or
                        (std.mem.eql(u8, color, "green") and count > 13) or
                        (std.mem.eql(u8, color, "blue") and count > 14))
                    {
                        break :game;
                    }
                }
            }
            possible_id_sum += game_id;
        }
        line.clearRetainingCapacity();
    }
    std.debug.print("possible games ID sum={}\n", .{possible_id_sum});
}

fn partTwo() !void {
    var file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var line = std.ArrayList(u8).init(gpa.allocator());
    defer line.deinit();

    var powers_sum: u32 = 0;

    var reader = file.reader();
    while (true) {
        reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        var line_it = std.mem.splitAny(u8, line.items, ":");
        _ = line_it.first();

        // Game
        var min_red: u32 = 0;
        var min_green: u32 = 0;
        var min_blue: u32 = 0;
        var sets_it = std.mem.splitAny(u8, line_it.rest(), ";");
        while (sets_it.next()) |set| {
            var balls_it = std.mem.splitAny(u8, set, ",");
            while (balls_it.next()) |ball| {
                var b_it = std.mem.splitAny(u8, std.mem.trim(u8, ball, " "), " ");
                var count = try std.fmt.parseInt(u32, b_it.first(), 10);
                var color = b_it.rest();
                if (std.mem.eql(u8, color, "red")) {
                    min_red = if (count > min_red) count else min_red;
                } else if (std.mem.eql(u8, color, "green")) {
                    min_green = if (count > min_green) count else min_green;
                } else if (std.mem.eql(u8, color, "blue")) {
                    min_blue = if (count > min_blue) count else min_blue;
                }
            }
        }
        powers_sum += min_red * min_green * min_blue;
        line.clearRetainingCapacity();
    }
    std.debug.print("powers sum={}\n", .{powers_sum});
}

pub fn main() !void {
    try partOne();
    try partTwo();
}
