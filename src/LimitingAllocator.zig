const std = @import("std");
const LimitingAllocator = @This();
const gimme = @import("./lib.zig");

counter: gimme.CountingAllocator,
limit: u64,

pub fn init(child_allocator: std.mem.Allocator, limit: u64) LimitingAllocator {
    return .{
        .counter = gimme.CountingAllocator.init(child_allocator),
        .limit = limit,
    };
}

pub fn allocator(self: *LimitingAllocator) std.mem.Allocator {
    return .{
        .ptr = self,
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .remap = remap,
            .free = free,
        },
    };
}

fn alloc(ctx: *anyopaque, len: usize, ptr_align: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    var self: *LimitingAllocator = @ptrCast(@alignCast(ctx));
    if (self.counter.count_active + len > self.limit) return null;
    return self.counter.allocator().rawAlloc(len, ptr_align, ret_addr) orelse return null;
}

fn resize(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    var self: *LimitingAllocator = @ptrCast(@alignCast(ctx));
    const old_len = buf.len;
    if (self.counter.count_active - old_len + new_len > self.limit) return false;
    return self.counter.allocator().rawResize(buf, buf_align, new_len, ret_addr);
}

fn remap(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    var self: *LimitingAllocator = @ptrCast(@alignCast(ctx));
    if (self.counter.count_active - memory.len + new_len > self.limit) return null;
    return self.counter.allocator().rawRemap(memory, alignment, new_len, ret_addr);
}

fn free(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, ret_addr: usize) void {
    var self: *LimitingAllocator = @ptrCast(@alignCast(ctx));
    return self.counter.allocator().rawFree(buf, buf_align, ret_addr);
}
