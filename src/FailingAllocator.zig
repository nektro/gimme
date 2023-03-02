const std = @import("std");
const FailingAllocator = @This();

pub fn allocator() std.mem.Allocator {
    return .{
        .ptr = undefined,
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .free = free,
        },
    };
}

fn alloc(ctx: *anyopaque, n: usize, log2_ptr_align: u8, ret_addr: usize) ?[*]u8 {
    _ = ctx;
    _ = n;
    _ = log2_ptr_align;
    _ = ret_addr;
    return null;
}

fn resize(ctx: *anyopaque, buf: []u8, log2_buf_align: u8, new_len: usize, ret_addr: usize) bool {
    _ = ctx;
    _ = buf;
    _ = log2_buf_align;
    _ = new_len;
    _ = ret_addr;
    return false;
}

fn free(ctx: *anyopaque, buf: []u8, log2_buf_align: u8, ret_addr: usize) void {
    _ = ctx;
    _ = buf;
    _ = log2_buf_align;
    _ = ret_addr;
    return {};
}

test FailingAllocator {
    try std.testing.expectError(error.OutOfMemory, FailingAllocator.allocator().alloc(u8, 1));
}
