#!/bin/bash

set -ex
RVHOME=/opt/riscv32
QEMUHOME=/opt/riscv32

# apt install -y autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev \
#                  gawk build-essential bison flex texinfo gperf libtool patchutils bc \
#                  zlib1g-dev libexpat-dev git \
#                  libglib2.0-dev libfdt-dev libpixman-1-dev \
#                  libncurses5-dev libncursesw5-dev ninja-build \
#                  python3 autopoint pkg-config zip unzip screen \
#                  make libxext-dev libxrender-dev libxtst-dev \
#                  libxt-dev libcups2-dev libfreetype6-dev \
#                  mercurial libasound2-dev cmake libfontconfig1-dev python3-pip

pip3 install docwriter

#git clone https://github.com/riscv/riscv-gnu-toolchain
tar xf riscv-gnu-toolchain.tbz

cd riscv-gnu-toolchain

git rm qemu
git submodule update --init --recursive

./configure --prefix=$RVHOME --with-arch=rv32gc --with-abi=ilp32d
make linux -j $(nproc)

echo "export PATH=$RVHOME/bin:\$PATH" >> /etc/profile

. /etc/profile

cd
tar xf qemu-5.2.0.tar.xz
cd qemu-5.2.0

./configure --target-list=riscv32-softmmu,riscv32-linux-user --prefix="$QEMUHOME"
make -j $(nproc) && make install

$QEMUHOME/bin/qemu-system-riscv32 --version

#. manual_install_deps.sh
#. build_ext_libs_32.sh
#. build_jdk.sh

