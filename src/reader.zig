const std = @import("std");

pub fn readFloatSlice(
    allocator: std.mem.Allocator,
    size: usize,
    offset: *usize,
    data: []const u8,
) ![]f32 {
    var slice = try allocator.alloc(f32, size);

    for (0..slice.len) |index| {
        slice[index] = readFloat(offset, data);
    }

    return slice;
}

pub fn readFloat(offset: *usize, data: []const u8) f32 {
    return @bitCast(readInt(u32, offset, data));
}

pub fn readInt(comptime T: type, offset: *usize, data: []const u8) T {
    const value = std.mem.readIntSliceLittle(T, data[offset.*..(offset.* + @sizeOf(T))]);

    offset.* += @sizeOf(T);

    return value;
}
