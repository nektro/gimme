const std = @import("std");
const CountingAllocator = @This();
const extras = @import("extras");

child_allocator: std.mem.Allocator,
count_active: u64,
count_active_strict: u64,
count_total: u64,

pub fn init(child_allocator: std.mem.Allocator) CountingAllocator {
    return .{
        .child_allocator = child_allocator,
        .count_active = 0,
        .count_active_strict = 0,
        .count_total = 0,
    };
}

pub fn allocator(self: *CountingAllocator) std.mem.Allocator {
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
    var self = extras.ptrCast(CountingAllocator, ctx);
    const ptr = self.child_allocator.rawAlloc(len, ptr_align, ret_addr) orelse return null;
    self.count_active += len;
    self.count_total += len;
    return ptr;
}

fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
    var self = extras.ptrCast(CountingAllocator, ctx);
    const old_len = buf.len;
    const stable = self.child_allocator.rawResize(buf, buf_align, new_len, ret_addr);
    self.count_active += new_len;
    self.count_active -= old_len;
    if (!stable) {
        self.count_active_strict += new_len;
        self.count_active_strict -= old_len;
    }
    self.count_total += new_len;
    return stable;
}

fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
    var self = extras.ptrCast(CountingAllocator, ctx);
    self.count_active -= buf.len;
    return self.child_allocator.rawFree(buf, buf_align, ret_addr);
}
