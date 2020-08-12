#!/bin/bash

# from https://github.com/llvm/circt/blob/master/README.md

set -e

TOP="$PWD"

git clone https://github.com/circt/circt.git
cd circt
sed -i 's,git@github.com:,https://github.com/,' .gitmodules
git submodule init
git submodule update
mkdir -p llvm/build
cd llvm/build
cmake -G Ninja ../llvm \
  -DLLVM_ENABLE_PROJECTS="mlir" \
  -DLLVM_TARGETS_TO_BUILD="X86;RISCV"  \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DCMAKE_BUILD_TYPE=DEBUG
ninja
ninja check-mlir

cd "$TOP"
mkdir circt/build
cd circt/build
cmake -G Ninja .. \
  -DMLIR_DIR=${TOP}/circt/llvm/build/lib/cmake/mlir \
  -DLLVM_DIR=${TOP}/circt/llvm/build/lib/cmake/llvm \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DCMAKE_BUILD_TYPE=DEBUG
ninja
ninja check-circt
