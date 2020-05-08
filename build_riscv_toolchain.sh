#!/bin/bash

# This script is extracted from docs in riscv-gnu-toolchain repo.

set -e

PREFIX="$HOME/opt/riscv"

git clone --recursive https://github.com/riscv/riscv-gnu-toolchain

cd riscv-gnu-toolchain

./configure --prefix="${PREFIX}"
make newlib -j $(nproc)
make linux -j $(nproc)

export PATH="$PATH:$PREFIX/bin"
export RISCV="$PREFIX"

echo If you want to use it in future works, add
echo
echo export PATH=\"\$PATH:$PREFIX/bin\"
echo export RISCV=\"$PREFIX\"
echo
echo to your \'.bashrc\' file.

