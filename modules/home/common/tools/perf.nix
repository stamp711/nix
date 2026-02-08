{
  description = "Performance profiling, tracing, and benchmarking tools";

  module =
    { pkgs, lib, ... }:
    {
      home.packages =
        with pkgs;
        [
          # Profiling
          samply # sampling profiler — outputs to Firefox Profiler format
          flamegraph # generate flamegraphs from perf/dtrace output
          inferno # Rust rewrite of flamegraph — faster, same CLI interface
          flamelens # TUI interactive flamegraph viewer

          # Benchmarking
          hyperfine # CLI benchmark runner — compare command execution times
          sysbench # system performance benchmark suite
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          # Profiling (Linux)
          perf # hardware counters, kernel-level profiling

          # Tracing (Linux)
          bpftrace # eBPF-based tracing: probe syscalls, uprobes, kprobes
          bcc # BPF toolkit: Python/C library + 100 pre-built tools (funccount, trace, etc.)
        ];
    };
}
