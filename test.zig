const gimme = @import("gimme");

test {
    _ = gimme.FailingAllocator;
    _ = gimme.CountingAllocator;
    _ = gimme.LivenessAllocator;
    _ = gimme.ZeroAllocator;
}
