# vc4-toolchain

The toolchain redox-rpi uses for the VideoCore IV VPU of the Raspberry Pi
(the processor that runs the boot firmware), with every part pinned to a
fixed commit:

| Part | What for | Source | Licence |
|---|---|---|---|
| vc4-tcc | our own C compiler for the VPU: TinyCC with a VC4 backend | [redox-rpi/tinycc](https://github.com/redox-rpi/tinycc) | LGPL-2.1-or-later |
| vc4-elf-gcc 6.2.1, binutils, newlib | the reference compiler; the firmware is built with it | [itszor/vc4-toolchain](https://github.com/itszor/vc4-toolchain) | GPL |
| vc4emul (resim) | VPU simulator for the tests | [itszor/resim](https://github.com/itszor/resim), fork of [mgottschlag/resim](https://github.com/mgottschlag/resim) | MIT (original); the fork's additions state none |
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

## resim and its licence

vc4emul needs local fixes for our tests: `asr` gives wrong results for
negative values and for a shift by 0, `bitflip` is missing, and we added
an instruction counter and a pc profile. resim was written by Mathias
Gottschlag (2012) and is MIT-licensed since 2020; the VC4 instructions
Julian Brown added in his fork (2015-16) carry no licence statement of
their own. His fork branched off before the licence file was added
(mgottschlag 77de984, 2020), so it lacks `LICENSE`; a redox-rpi fork would
take that commit too. Until it is decided where our fixes live, they stay
a patch on the build host
(`RESIM_PATCH=file ./build.sh resim`). Without the patch, tests with
negative right shifts fail.

## Changing a version

Change `toolchain.lock` in a pull request, run `./test.sh` (with
`FIRMWARE`), and put the result in the PR. The plan and decisions for
vc4-tcc are in rpi-open-firmware
[docs/tcc-vc4.md](https://github.com/redox-rpi/rpi-open-firmware/blob/redox-rpi/docs/tcc-vc4.md).
