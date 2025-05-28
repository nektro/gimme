const std = @import("std");
const LivenessAllocator = @This();
const extras = @import("extras");

child_allocator: std.mem.Allocator,
count: u64,

pub fn init(child_allocator: std.mem.Allocator) LivenessAllocator {
    return .{
        .child_allocator = child_allocator,
        .count = 0,
    };
}

pub fn allocator(self: *LivenessAllocator) std.mem.Allocator {
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
    var self = extras.ptrCast(LivenessAllocator, ctx);
    const ptr = self.child_allocator.rawAlloc(len, ptr_align, ret_addr) orelse return null;
    self.count += len;
    return ptr;
}

fn resize(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    var self = extras.ptrCast(LivenessAllocator, ctx);
    const stable = self.child_allocator.rawResize(buf, buf_align, new_len, ret_addr);
    if (!stable) self.count += new_len;
    return stable;
}

fn remap(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    var self = extras.ptrCast(LivenessAllocator, ctx);
    const memory_new = self.child_allocator.rawRemap(memory, alignment, new_len, ret_addr) orelse return null;
    if (memory_new != memory.ptr) self.count -= memory.len;
    if (memory_new != memory.ptr) self.count += new_len;
    return memory_new;
}

fn free(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, ret_addr: usize) void {
    var self = extras.ptrCast(LivenessAllocator, ctx);
    defer self.count -= buf.len;
    return self.child_allocator.rawFree(buf, buf_align, ret_addr);
}
