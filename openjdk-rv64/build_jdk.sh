#!/bin/bash
set -ex
. /etc/profile

RVHOME=/opt/riscv64

git clone https://github.com/openjdk-riscv/bishengjdk-11-mirror.git bishengjdk-11
cd bishengjdk-11
git checkout 810e92


wget https://download.java.net/openjdk/jdk10/ri/jdk-10_linux-x64_bin_ri.tar.gz
tar -xzvf jdk-10_linux-x64_bin_ri.tar.gz

JDK10HOME=$PWD/jdk-10

bash configure \
--openjdk-target=riscv64-unknown-linux-gnu \
--disable-warnings-as-errors \
--with-sysroot=${RVHOME}/sysroot \
--x-includes=${RVHOME}/sysroot/usr/include \
--x-libraries=${RVHOME}/sysroot/usr/lib \
--with-boot-jdk=${JDK10HOME} \
--with-debug-level=slowdebug \
--with-native-debug-symbols=internal \
--with-jvm-variants=core

make JOBS=$(nproc)