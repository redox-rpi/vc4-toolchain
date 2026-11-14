#!/bin/bash
# Builds the pinned VC4 toolchain (toolchain.lock) in $WORK.
#
#   ./build.sh [tinycc] [resim] [gcc]     (default: tinycc resim)
#
#   WORK=dir          where sources and builds go (default ./work)
#   JOBS=n            parallel make jobs (default nproc)
#
# Results: $WORK/tinycc/vc4-tcc, $WORK/resim/build/vc4emul/vc4emul and, for gcc,
# $WORK/vc4-toolchain/prefix/bin/vc4-elf-*. gcc takes about an hour and
# downloads GCC's prerequisites (gmp, mpfr, mpc).
set -eu
here=$(cd "$(dirname "$0")" && pwd)
. "$here/toolchain.lock"
work=$(mkdir -p "${WORK:-$here/work}" && cd "${WORK:-$here/work}" && pwd)
jobs=${JOBS:-$(nproc)}
log() { echo "== $*"; }

# fetch <url> <commit> <dir>: the repository at exactly that commit
fetch() {
	[ -d "$3/.git" ] || git clone -q --no-checkout "$1" "$3"
	git -C "$3" cat-file -e "$2^{commit}" 2>/dev/null || git -C "$3" fetch -q origin
	git -C "$3" checkout -q --detach "$2"
}

build_tinycc() {
	log "tinycc $TINYCC_COMMIT"
	fetch "$TINYCC_URL" "$TINYCC_COMMIT" "$work/tinycc"
	cd "$work/tinycc"
	[ -f config.mak ] || ./configure --config-bcheck=no --config-backtrace=no > /dev/null
	make -s -j"$jobs" vc4-tcc
	log "$work/tinycc/vc4-tcc"
}

build_resim() {
	log "resim $RESIM_COMMIT"
	fetch "$RESIM_URL" "$RESIM_COMMIT" "$work/resim"
	cd "$work/resim"
	cmake -S . -B build > /dev/null
	make -C build -s -j"$jobs" vc4emul
	log "$work/resim/build/vc4emul/vc4emul"
}

build_gcc() {
	log "vc4-toolchain $VC4_TOOLCHAIN_COMMIT (GCC 6.2.1)"
	fetch "$VC4_TOOLCHAIN_URL" "$VC4_TOOLCHAIN_COMMIT" "$work/vc4-toolchain"
	cd "$work/vc4-toolchain"
	git submodule update -q --init binutils-vc4 gcc-vc4 newlib
	for m in "binutils-vc4 $VC4_BINUTILS_COMMIT" "gcc-vc4 $VC4_GCC_COMMIT" "newlib $VC4_NEWLIB_COMMIT"; do
		set -- $m
		case $(git -C "$1" rev-parse HEAD) in "$2"*) ;; *)
			echo "$1 is not at $2 (toolchain.lock)" >&2; exit 1;; esac
	done
	(cd gcc-vc4 && ./contrib/download_prerequisites)
	./build-all.sh -no-c++
	log "$work/vc4-toolchain/prefix/bin/vc4-elf-gcc"
}

[ $# -gt 0 ] || set -- tinycc resim
for part; do
	case $part in
		tinycc|resim|gcc) (build_$part) ;;
		*) echo "unknown part: $part (tinycc, resim, gcc)" >&2; exit 2 ;;
	esac
done
