# prepare for riscv-gnu-toolchain and dejagnu
apt-get update && apt-get install git build-essential tcl expect flex texinfo bison libpixman-1-dev libglib2.0-dev pkg-config zlib1g-dev ninja-build gawk python
# clone riscv-gnu-toolchain and set the branch
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
git submodule update --init --recursive
cd riscv-gcc
git remote add zfinx https://github.com/pz9115/riscv-gcc.git
git fetch zfinx
git checkout zfinx/riscv-gcc-10.2.0-zfinx
cd ../riscv-binutils
git remote add zfinx https://github.com/pz9115/riscv-binutils-gdb.git
git fetch zfinx
git checkout zfinx/riscv-binutils-2.35-zfinx
cd ../qemu
git remote add plct-qemu https://github.com/isrc-cas/plct-qemu.git
git fetch plct-qemu
git checkout plct-qemu/plct-zfinx-dev
git reset --hard d73c46e4a84e47ffc61b8bf7c378b1383e7316b5
cd ..

# set configure for different abi
# for rv64:
./configure --prefix=$HOME/opt/rv64/ --with-arch=rv64gc --with-abi=lp64 --with-multilib-generator="rv64gc-lp64--"

# for rv32:
# ./configure --prefix=$HOME/opt/rv32/ --with-arch=rv32gc --with-abi=ilp32 --with-multilib-generator="rv32gc-ilp32--"

# for rv32e:
# ./configure --prefix=$HOME/opt/rv32e/ --with-arch=rv32ec --with-abi=ilp32e --with-multilib-generator="rv32ec-ilp32e--"

# you can use make -j* to make speed up
make check-gcc-newlib
make check-binutils-newlib
# see the report
make report-gcc-newlib 2>&1| tee gcc_log.log
make report-binutils-newlib 2>&1|tee binutils_log.log
# Use `make clean` to re-check different abi, reset configure and remake for other abi again (lp64\ilp32\ilp32e)