git submodule update --init
cd riscv-gcc
git checkout riscv-gcc-10.2.0
cd ..

# Temp Fix. See:
#    https://github.com/riscv/riscv-gnu-toolchain/issues/736
cd qemu
git checkout master
git pull
cd ..

git submodule update --init --recursive

# test:
./configure --prefix="$PWD/obj-rv64gc/" --enable-multilib

# you can use make -j* to make speed up
make -j $(nproc) check-gcc-newlib
make -j $(nproc) check-binutils-newlib
make report-gcc-newlib
make report-binutils-newlib

