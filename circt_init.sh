#!/bin/bash

# from https://github.com/llvm/circt/blob/master/README.md

set -e

TOP="$PWD"

ensure_cmake () {
  echo "Make sure your cmake version is above 3.13.4:"
  echo "your version is: `cmake --version`"
  echo
  echo "I will download and use the latest sable cmake,"
  echo "Press any key other than enter to skip this step."
  echo "or press ENTER to continue to download & build cmkae."

  read -t 5 -p "You have 5 seconds to refuse, or I'll continue:" cmake_yes || echo "yes"

  if [ -z "$cmake_yes" ]; then
    CMAKE_FILE=cmake-3.18.1.tar.gz
    CMAKE_DIR=${CMAKE_FILE%.tar.gz}
    wget https://github.com/Kitware/CMake/releases/download/v3.18.1/$CMAKE_FILE
    tar xf $CMAKE_FILE
    cd $CMAKE_DIR
    [ -d "$HOME/bin" ] || mkdir -p "$HOME/bin"
    ./configure --prefix="$HOME/bin" --parallel=$(nproc)
    make install -j $(nproc)
    export PATH="$HOME/bin/bin:$PATH"
    echo 'export PATH="$HOME/bin/bin:$PATH"' >> $HOME/.bashrc
  fi
}

ensure_cmake

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
