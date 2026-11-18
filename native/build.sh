#!/bin/bash
# Builds the engine bridge. Usage: native/build.sh [linux] [macos] [windows]
# Needs g++ for linux and `pip install ziglang` for the macOS and Windows cross-builds.
set -e
cd "$(dirname "$0")"
OUT=../bin
mkdir -p $OUT build
one() {  # target-name compiler-prefix extra-flags
	local T=$1; shift; local CXX="$1"; shift; local FLAGS="$*"
	mkdir -p build/$T
	local jobs=()
	for f in lua/cpp/*.cpp; do
		o=build/$T/l_$(basename $f .cpp).o
		[ -f $o ] || echo "$CXX $FLAGS -O2 -std=c++17 -Ilua/src -Ilua -c $f -o $o"
	done > build/$T/cmds.txt
	for f in ocgcore/*.cpp; do
		o=build/$T/$(basename $f .cpp).o
		[ -f $o ] || echo "$CXX $FLAGS -O2 -std=c++17 -fno-rtti -DOCGCORE_EXPORT_FUNCTIONS -Ilua/src -Ilua -c $f -o $o"
	done >> build/$T/cmds.txt
	xargs -P 2 -I{} sh -c "{}" < build/$T/cmds.txt
	$CXX $FLAGS -O2 -std=c++17 -I. -Ilua/src -c bridge.cpp -o build/$T/zz_bridge.o
}
for what in "$@"; do
	case $what in
	linux)
		one linux "g++" -fPIC -fvisibility=hidden
		g++ -shared -o $OUT/libocgbridge.linux.x86_64.so build/linux/*.o -static-libstdc++ -static-libgcc -Wl,--exclude-libs,ALL
		;;
	macos)
		for A in aarch64 x86_64; do
			one $A-macos "python3 -m ziglang c++ -target $A-macos" -fvisibility=hidden
			python3 -m ziglang c++ -target $A-macos -shared -o build/ocgbridge.$A.dylib build/$A-macos/*.o
		done
		python3 fat.py build/ocgbridge.aarch64.dylib build/ocgbridge.x86_64.dylib $OUT/libocgbridge.macos.dylib
		;;
	windows)
		one x86_64-windows-gnu "python3 -m ziglang c++ -target x86_64-windows-gnu"
		python3 -m ziglang c++ -target x86_64-windows-gnu -shared -o $OUT/ocgbridge.windows.x86_64.dll build/x86_64-windows-gnu/*.o
		rm -f $OUT/*.lib $OUT/*.pdb
		;;
	esac
done
ls -la $OUT
