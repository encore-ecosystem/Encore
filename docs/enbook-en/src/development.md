# Development and Performance

Start with a correct, testable program. Measure before choosing a more complex
representation or introducing concurrency.

## A short feedback loop

Run `encore format --check`, `encore check`, and a focused `encore test --filter`
while changing a function. Run the relevant complete package tests before
shipping. `check` does not replace a native build: linking, runtime behavior,
and platform dependencies need executable verification.

Keep `encore.toml` and `encore.lock` together. Use `sync` to restore dependencies
and `update` only when selecting newer ones intentionally. Development `path@`
references do not make a published package portable: consumers need published
dependencies. See [packages](packages.md) and [publishing](publishing-packages.md).

## Measure the right thing

Separate cold compilation, warm incremental compilation, application startup,
and steady-state execution. Comparing a cached build with a clean build says
nothing about the optimizer's speed. Record the compiler release, target,
profile, input size, repetitions, elapsed time, and memory when relevant.

Use `release` for a portable optimization baseline; use `extreme` when its
native toolchain requirements and CPU tuning are appropriate. Do not distribute
a host-tuned binary to unknown CPUs without configuring a suitable baseline.
See [Getting Started](getting-started.md) for profiles and [targets](targets.md)
for the host/target distinction.

For runtime timings use the monotonic `std::time::perf_counter_ns` or
`perf_counter_ms`, not wall-clock calendar time. Avoid printing inside the hot
loop. Warm up separately, repeat measurements, and verify the output so an
incorrect or optimized-away computation does not look like an improvement.

## Understand the cost model

Generic specialization trades potential code growth for concrete dispatch.
`dyn Trait` introduces runtime dispatch. Copying an inline payload copies its
fields; copying a node handle shares storage and participates in ownership.
Cloning a collection allocates independent storage. Repeated string concatenation
can allocate repeatedly. Native threads have startup and join overhead; dividing
tiny tasks into many threads can be slower than a sequential loop.

These are reasons to measure, not universal claims that one construct is slow.
The [parallel project](parallel-project.md) checks correctness before speed.

## Caches and debugging

Registry caches hold downloaded dependencies; build caches hold compilation
work; LSP caches hold analysis metadata. They solve different problems. Do not
delete all three as the first response to an unresolved import. First check
the manifest, lockfile, selected compiler, and the failing command's output.

When reporting a cache regression, compare the same source and compiler with
a warm build and a clean **project-local** build directory, preserving logs.
Do not remove a global installation or registry just to force a rebuild.

**Exercise:** a warm compile takes less time after adding a worker. Is that
evidence that runtime parallelism improved?

<details><summary>Answer</summary>

No. Compilation and execution are different measurements, and the cache state
changed. Time the same verified executable workload with the same inputs.

</details>
