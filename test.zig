const std = @import("std");
const gimme = @import("gimme");

test {
    std.testing.refAllDecls(gimme.FailingAllocator);
    std.testing.refAllDecls(gimme.CountingAllocator);
    std.testing.refAllDecls(gimme.LivenessAllocator);
    std.testing.refAllDecls(gimme.ZeroAllocator);
}
