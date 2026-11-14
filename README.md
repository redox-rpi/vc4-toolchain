# vc4-toolchain

The toolchain redox-rpi uses for the VideoCore IV VPU of the Raspberry Pi
(the processor that runs the boot firmware), with every part pinned to a
fixed commit:

| Part | What for | Source | Licence |
|---|---|---|---|
| vc4-tcc | our own C compiler for the VPU: TinyCC with a VC4 backend | [redox-rpi/tinycc](https://github.com/redox-rpi/tinycc) | LGPL-2.1-or-later |
| vc4-elf-gcc 6.2.1, binutils, newlib | the reference compiler; the firmware is built with it | [itszor/vc4-toolchain](https://github.com/itszor/vc4-toolchain) | GPL |
| vc4emul (resim) | VPU simulator for the tests | [redox-rpi/resim](https://github.com/redox-rpi/resim), our fork of [mgottschlag/resim](https://github.com/mgottschlag/resim) with Julian Brown's additions and our fixes | MIT |
| csmith, creduce | random-program tests | Ubuntu packages | BSD-style |

This repository holds no copies of them: only the pinned versions
(`toolchain.lock`) and the scripts that build and test them. Its own files
are MIT.

## Build and test

```bash
./build.sh                 # vc4-tcc and vc4emul in ./work
./build.sh gcc             # GCC 6.2.1 as well (about an hour)
./test.sh                  # encoder, assembler and ABI tests
FIRMWARE=~/rpi-open-firmware ./test.sh   # also FAT and whole-bootcode tests
```

Needs gcc, make, cmake, python3 and git; for `build.sh gcc` also the GCC
build dependencies (flex, bison, texinfo). `VC4_PREFIX` points the tests
at a GCC toolchain built elsewhere.

## resim

The simulator is our fork [redox-rpi/resim](https://github.com/redox-rpi/resim)
of Mathias Gottschlag's original (MIT). It merges Julian Brown's VC4
additions (the version the GCC toolchain uses) and adds what vc4-tcc's
tests need: `asr` fixed, `switch` (GCC jump tables), `bitflip`, `abs`, an
instruction counter (`VC4EMUL_COUNT`) and a pc profile (`VC4EMUL_PROF`).
Its README has the origin of every part, the other forks and the licence
notes. Status of all sources redox-rpi uses: rpi-open-firmware
[docs/sources.md](https://github.com/redox-rpi/rpi-open-firmware/blob/redox-rpi/docs/sources.md).

## Changing a version

Change `toolchain.lock` in a pull request, run `./test.sh` (with
`FIRMWARE`), and put the result in the PR. The decisions for vc4-tcc are
in redox-rpi/tinycc
[docs/vc4-decisions.md](https://github.com/redox-rpi/tinycc/blob/main/docs/vc4-decisions.md).
