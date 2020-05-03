#!/bin/bash

# This is a script extracts all RISCV64GC related commands
# from <RISC-V - Getting Started Guide> by RISC-V Foundation.
# Publish date of the RISC-V manual: 2019-05-31

# Zephyr is skipped.

echo "Auto run commands in <RISC-V - Getting Started Guide>"
echo "    Author: RISC-V Foundation; Date: 2019-05-31"

# 8.1

echo "Assume we are on Ubuntu 18.04"
sudo apt install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev \
gawk build-essential bison flex texinfo gperf libtool patchutils bc \
zlib1g-dev libexpat-dev git

mkdir riscv64-linux || true
pushd riscv64-linux

# 8.2
# NOTICE: In mainland China repo clone is a pain in your _.
#         JUST USE YOUR OVERSEA NODES.

git clone --recursive --depth 3 https://github.com/riscv/riscv-gnu-toolchain
git clone --recursive --depth 3 https://github.com/qemu/qemu
git clone --recursive --depth 3 https://github.com/torvalds/linux
git clone --recursive --depth 3 https://github.com/riscv/riscv-pk
git clone --recursive --depth 3 https://github.com/michaeljclark/busybear-linux

# use subshell for convinence.

( cd riscv-gnu-toolchain
# pick an install path, e.g. /opt/riscv64
./configure --prefix=/opt/riscv64 --with-abi=lp64
make newlib -j $(nproc)
make linux -j $(nproc)
# export variables
export PATH="$PATH:/opt/riscv64/bin"
export RISCV="/opt/riscv64"
)

(cd qemu
git checkout v3.0.0
./configure --target-list=riscv64-softmmu
make -j $(nproc)
sudo make install
)

(cd linux
git checkout v4.19-rc3
cp ../busybear-linux/conf/linux.config .config
make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- olddefconfig

# enter kernel configuration
make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- nconfig

# 64-bit
# • ARCH_RV64I
# • CMODEL_MEDANY
# • CONFIG_SIFIVE_PLIC
# 
# 32-bit
# • ARCH_RV32I
# • CMODEL_MEDLOW
# • CONFIG_SIFIVE_PLIC

make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- vmlinux -j $(nproc)
)

(cd riscv-pk
mkdir build && cd build
../configure --enable-logo --host=riscv64-unknown-elf --with-payload=../../linux/vmlinux
make -j $(nproc)
)


(cd busybear-linux
make -j $(nproc)
)

(while sleep 60; do echo "PLCT NOTICE: Use <Ctrl-A> X to quit QEMU ;-)"; done ) &

qemu-system-riscv64 -nographic -machine virt \
-kernel riscv-pk/build/bbl -append "root=/dev/vda ro console=ttyS0" \
-drive file=busybear-linux/busybear.bin,format=raw,id=hd0 \
-device virtio-blk-device,drive=hd0

# Use Ctrl-A X to quit QEMU :-)
