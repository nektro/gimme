const std = @import("std");
const CountingAllocator = @This();

child_allocator: std.mem.Allocator,
count_active: u64,
count_total: u64,
count_allocs: u64,
count_allocs_success: u64,
count_resizes: u64,
count_frees: u64,

pub fn init(child_allocator: std.mem.Allocator) CountingAllocator {
    return .{
        .child_allocator = child_allocator,
        .count_active = 0,
        .count_total = 0,
        .count_allocs = 0,
        .count_allocs_success = 0,
        .count_resizes = 0,
        .count_frees = 0,
    };
}

pub fn allocator(self: *CountingAllocator) std.mem.Allocator {
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
    var self: *CountingAllocator = @ptrCast(@alignCast(ctx));
    self.count_allocs += 1;
    const ptr = self.child_allocator.rawAlloc(len, ptr_align, ret_addr) orelse return null;
    self.count_allocs_success += 1;
    self.count_active += len;
    self.count_total += len;
    return ptr;
}

fn resize(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    var self: *CountingAllocator = @ptrCast(@alignCast(ctx));
    self.count_resizes += 1;
    const old_len = buf.len;
    const stable = self.child_allocator.rawResize(buf, buf_align, new_len, ret_addr);
    if (stable) {
        if (new_len > old_len) {
            self.count_active += new_len;
            self.count_active -= old_len;
            self.count_total += new_len;
            self.count_total -= old_len;
        } else {
            self.count_active -= old_len;
            self.count_active += new_len;
            self.count_total -= old_len;
            self.count_total += new_len;
        }
    }
    return stable;
}

fn remap(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    var self: *CountingAllocator = @ptrCast(@alignCast(ctx));
    const memory_new = self.child_allocator.rawRemap(memory, alignment, new_len, ret_addr) orelse return null;
    if (memory_new != memory.ptr) self.count_active -= memory.len;
    if (memory_new != memory.ptr) self.count_active += new_len;
    if (memory_new != memory.ptr) self.count_total -= memory.len;
    if (memory_new != memory.ptr) self.count_total += new_len;
    return memory_new;
}

fn free(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, ret_addr: usize) void {
    var self: *CountingAllocator = @ptrCast(@alignCast(ctx));
    self.count_frees += 1;
    self.count_active -= buf.len;
    return self.child_allocator.rawFree(buf, buf_align, ret_addr);
}
