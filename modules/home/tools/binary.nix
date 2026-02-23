{
  description = "Binary inspection, reverse engineering, and debugging tools";

  module =
    { pkgs, lib, ... }:
    {
      home.packages =
        with pkgs;
        [
          # ELF inspection
          elf-info # quick ELF header summary
          binsider # TUI binary analyzer
          file # file type identification via magic bytes
          pwntools # CTF framework with checksec, ROPgadget, asm/disasm, and exploit utilities

          # Hex viewing
          hexyl # modern colored hex viewer

          # Patching
          patchelf # modify ELF rpath, interpreter, SONAME

          # Reverse engineering
          rizin # RE framework: disassembler, debugger, hex editor (modern radare2 fork)
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          # ELF inspection
          elfutils # eu-readelf, eu-objdump, eu-nm - better DWARF support than binutils

          # Debuggers & tracers (Linux)
          gdb # GNU debugger
          strace # system call tracer

          # Memory & runtime analysis (Linux)
          valgrind # memory debugger, profiler, leak detector
        ];
    };
}
