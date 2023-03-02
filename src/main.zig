const gimme = @import("gimme");

test {
    _ = gimme.FailingAllocator;
    _ = gimme.CountingAllocator;
}
