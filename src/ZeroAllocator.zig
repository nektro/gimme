const std = @import("std");
const ZeroAllocator = @This();
const extras = @import("extras");

child_allocator: std.mem.Allocator,

pub fn init(child_allocator: std.mem.Allocator) ZeroAllocator {
    return .{
        .child_allocator = child_allocator,
    };
}

pub fn allocator(self: *ZeroAllocator) std.mem.Allocator {
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
    var self = extras.ptrCast(ZeroAllocator, ctx);
    const ptr = self.child_allocator.rawAlloc(len, ptr_align, ret_addr) orelse return null;
    @memset(ptr[0..len], 0);
    return ptr;
}

fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
    var self = extras.ptrCast(ZeroAllocator, ctx);
    const stable = self.child_allocator.rawResize(buf, buf_align, new_len, ret_addr);
    if (!stable) @memset(buf, 0);
    return stable;
}

fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
    var self = extras.ptrCast(ZeroAllocator, ctx);
    return self.child_allocator.rawFree(buf, buf_align, ret_addr);
}

test ZeroAllocator {
    {
        const a = try std.testing.allocator.alloc(usize, 1);
        defer std.testing.allocator.free(a);
        try std.testing.expect(a[0] == undefined);
    }
    {
        var z = ZeroAllocator.init(std.testing.allocator);
        const l = z.allocator();

        const a = try l.alloc(usize, 1);
        defer l.free(a);
        try std.testing.expect(a[0] == undefined);
    }
}
