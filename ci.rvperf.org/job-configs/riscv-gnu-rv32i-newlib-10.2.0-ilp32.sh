# riscv-gnu-rv32i-newlib-10.2.0-ilp32

git submodule update --init
cd riscv-gcc
git checkout riscv-gcc-10.2.0
cd ..


# only test on riscv32i
./configure --prefix=$PWD/obj-rv32i/ --disable-linux --with-arch=rv32i --with-abi=ilp32
make -j $(nproc) newlib
make -j $(nproc) report-newlib SIM=gdb
