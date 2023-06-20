const std = @import("std");
const LimitingAllocator = @This();
const extras = @import("extras");
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
            .free = free,
        },
    };
}

fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
    var self = extras.ptrCast(LimitingAllocator, ctx);
    if (self.counter.count_active + len > self.limit) return null;
    return self.counter.allocator().rawAlloc(len, ptr_align, ret_addr) orelse return null;
}

fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
    var self = extras.ptrCast(LimitingAllocator, ctx);
    const old_len = buf.len;
    if (self.counter.count_active - old_len + new_len > self.limit) return false;
    return self.counter.allocator().rawResize(buf, buf_align, new_len, ret_addr);
}

fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
    var self = extras.ptrCast(LimitingAllocator, ctx);
    return self.counter.allocator().rawFree(buf, buf_align, ret_addr);
}
