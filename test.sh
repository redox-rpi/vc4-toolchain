#!/bin/bash
# Runs vc4-tcc's tests (tinycc tests/vc4) with the tools from build.sh.
#
#   ./test.sh
#
#   WORK=dir          as for build.sh (default ./work)
#   VC4_PREFIX=pfx    GCC toolchain prefix (default: the one build.sh gcc
#                     made, else vc4-elf- from PATH)
#   FIRMWARE=dir      an rpi-open-firmware checkout (fat-boot a8bcbe7 or
#                     later): also runs fat-sim.sh and bootcode-build.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
work=${WORK:-$here/work}
tcc=$work/tinycc
emul=$work/resim/build/vc4emul/vc4emul
prefix=${VC4_PREFIX:-}
if [ -z "$prefix" ]; then
	if [ -x "$work/vc4-toolchain/prefix/bin/vc4-elf-gcc" ]; then
		prefix=$work/vc4-toolchain/prefix/bin/vc4-elf-
	else
		prefix=vc4-elf-
	fi
fi
command -v "${prefix}gcc" > /dev/null || { echo "no ${prefix}gcc (VC4_PREFIX)" >&2; exit 2; }
[ -x "$tcc/vc4-tcc" ] && [ -x "$emul" ] || { echo "run ./build.sh first" >&2; exit 2; }

fail=0
run() { # name command...
	local name=$1; shift
	if out=$("$@" 2>&1); then
		echo "ok    $name: $(echo "$out" | tail -1)"
	else
		echo "FAIL  $name"; echo "$out" | tail -15 | sed 's/^/      /'; fail=1
	fi
}
cd "$tcc"
run enc     python3 tests/vc4/enc-test.py "$prefix"
run asm     tests/vc4/asm-test.sh "$prefix"
run abi     tests/vc4/abi-sim.sh "$prefix" "$emul"
if [ -n "${FIRMWARE:-}" ]; then
	run fat      tests/vc4/fat-sim.sh "$FIRMWARE" "$prefix" "$emul"
	run bootcode env LINK=tcc tests/vc4/bootcode-build.sh "$FIRMWARE" "$prefix"
fi
exit $fail
