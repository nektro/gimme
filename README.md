# gimme

`gimme` is a yummy collection of useful `Allocator`s.

The allocators included are:
- FailingAllocator
- UnreachableAllocator
- PanicAllocator
- CountingAllocator
- LivenessAllocator
- ZeroAllocator
- LimitingAllocator

# Failing Allocator

FailingAllocator simulates failure for every memory operation. 
The alloc always returns `null` (indicating out-of-memory error), the resize always returns `false` and free does nothing. 
Useful for testing for simulating allocation failure

# UnreachableAllocator

UnreachableAllocator acts as a placeholder or safeguard in places where memory allocation, resizing or freeing should never occur.

# PanicAllocator

PanicAllocator provides an allocator that intentionally triggers a panic whenever an allocation, resizing, or freeing operation is attempted. 
This can be used to debug parts which should not allocate memory.

# CountingAllocator

CountingAllocator wraps around a given allocator. It performs all allocator operations and also tracks some statistics related to these operations.

# LivenessAllocator

LivenessAllocator wraps around an allocator and tracks the total amount of memory currently allocated (or "live") at any given time. 

# ZeroAllocator

ZeroAllocator wraps around a child allocator and zeroes out the allocated memory.

# LimitingAllocator

LimitingAllocator wraps around a child allocator and limits the total amount of memory that can be allocated at any given time.

See `src/lib.zig` for more.
