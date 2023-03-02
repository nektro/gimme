const std = @import("std");

pub const FailingAllocator = @import("./FailingAllocator.zig");

test {
    _ = FailingAllocator;
}
