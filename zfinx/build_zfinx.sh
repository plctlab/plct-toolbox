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
cd ..

# set configure for different abi
# for rv64:
./configure --prefix=$HOME/opt/rv64/ --with-arch=rv64gczfinx --with-abi=lp64 --with-multilib-generator="rv64gczfinx-lp64--"

# for rv32:
# ./configure --prefix=$HOME/opt/rv32/ --with-arch=rv32gczfinx --with-abi=ilp32 --with-multilib-generator="rv32gczfinx-ilp32--"

# for rv32e:
# ./configure --prefix=$HOME/opt/rv32e/ --with-arch=rv32eczfinx --with-abi=ilp32e --with-multilib-generator="rv32eczfinx-ilp32e--"

# you can use make -j* to make speed up
make