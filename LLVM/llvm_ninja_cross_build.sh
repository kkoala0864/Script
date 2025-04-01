#! /bin/bash
export LLVM_ROOT="/home/neil/LLVM_Project/"
export SRC_ROOT="${LLVM_ROOT}/llvm_src/"

export X_TOOL="${LLVM_ROOT}/x_compiler/armv7-unknown-linux-gnueabihf/bin"
export CC="arm-linux-gnueabihf-gcc"
export CXX="arm-linux-gnueabihf-g++"

cmake -G "Ninja" \
	-DCMAKE_INSTALL_PREFIX="${LLVM_ROOT}/llvm_ninja_cross/bin" \
	-DLLVM_TARGET_ARCH="X86" \
	-DLLVM_TARGETS_TO_BUILD="ARM" \
	-DLLVM_DEFAULT_TARGET_TRIPLE=arm-linux-gnueabihf \
	-DDEFAULT_SYSROOT="${X_TOOL}/../arm-linux-gnueabihf/libc" \
	$SRC_ROOT
	
