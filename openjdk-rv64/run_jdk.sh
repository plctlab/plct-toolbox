#!/bin/bash
set -ex
. /etc/profile

RVHOME=/opt/riscv64

cd bishengjdk-11

cd build/linux-riscv64-normal-core-slowdebug/jdk/bin
/opt/riscv64/bin/qemu-riscv64 -L ${RVHOME}/sysroot ./java -version
#/opt/riscv64/bin/qemu-riscv64 -L ${RVHOME}/sysroot ./java -XX:+TraceBytecodes  -version
