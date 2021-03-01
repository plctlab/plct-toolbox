#!/bin/bash

#apt-get install git build-essential tcl expect flex texinfo bison libpixman-1-dev libglib2.0-dev pkg-config zlib1g-dev ninja-build

#git clone https://github.com/riscv/riscv-gnu-toolchain 
#cd riscv-gnu-toolchain
git submodule update --init
#cd ..
#cp riscv-gnu-toolchain zfinx -r && cd zfinx

cd riscv-gcc
git remote | grep -q zfinx || git remote add zfinx https://github.com/pz9115/riscv-gcc.git
git fetch zfinx
git checkout -f zfinx/riscv-gcc-10.2.0-zfinx
cd ../riscv-binutils
git remote | grep -q zfinx || git remote add zfinx https://github.com/pz9115/riscv-binutils-gdb.git
git fetch zfinx
git checkout zfinx/riscv-binutils-2.35-zfinx
cd ../qemu
git remote | grep -q plct-qemu || git remote add plct-qemu https://github.com/isrc-cas/plct-qemu.git || true
git fetch plct-qemu
git checkout plct-qemu/plct-zfinx-dev
git reset --hard d73c46e4a84e47ffc61b8bf7c378b1383e7316b5

cd ..

# for rv64:
./configure --prefix="$PWD/opt-rv64/" --with-arch=rv64gc --with-abi=lp64 --with-multilib-generator="rv64gc-lp64--"

# you can use make -j* to make speed up
make -j $(nproc) check-gcc-newlib
make -j $(nproc) check-binutils-newlib
make report-gcc-newlib
make report-binutils-newlib
# Use `make clean` to re-check different abi, reset configure and remake for other abi again (lp64\ilp32\ilp32e)
make clean

# for rv32:
./configure --prefix=$PWD/opt-rv32/ --with-arch=rv32gc --with-abi=ilp32 --with-multilib-generator="rv32gc-ilp32--"

# you can use make -j* to make speed up
make -j $(nproc) check-gcc-newlib
make -j $(nproc) check-binutils-newlib
make report-gcc-newlib
make report-binutils-newlib
# Use `make clean` to re-check different abi, reset configure and remake for other abi again (lp64\ilp32\ilp32e)
make clean

# for rv32e:
./configure --prefix=$PWD/opt-rv32e/ --with-arch=rv32ec --with-abi=ilp32e --with-multilib-generator="rv32ec-ilp32e--"

# you can use make -j* to make speed up
make -j $(nproc) check-gcc-newlib
make -j $(nproc) check-binutils-newlib
make report-gcc-newlib
make report-binutils-newlib
# Use `make clean` to re-check different abi, reset configure and remake for other abi again (lp64\ilp32\ilp32e)
make clean
