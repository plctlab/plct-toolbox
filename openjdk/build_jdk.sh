#!/bin/bash
set -ex
. /etc/profile

RVHOME=/opt/riscv32

git clone https://github.com/openjdk-riscv/jdk11u.git
cd jdk11u
git checkout 96943a


wget https://download.java.net/openjdk/jdk10/ri/jdk-10_linux-x64_bin_ri.tar.gz
tar -xzvf jdk-10_linux-x64_bin_ri.tar.gz

JDK10HOME=$PWD/jdk-10

bash configure \
--openjdk-target=riscv32-unknown-linux-gnu \
--disable-warnings-as-errors \
--with-sysroot=${RVHOME}/sysroot \
--with-boot-jdk=${JDK10HOME} \
--with-native-debug-symbols=none \
--with-jvm-variants=zero \
--with-jvm-interpreter=cpp \
--prefix=$PWD/nodebug_32

make JOBS=$(nproc)  && make install

# check

#cd nodebug_32/jvm/openjdk-11.0.9-internal/bin
#/opt/riscv32/bin/qemu-riscv32 -L ${RVHOME} ./java -version
