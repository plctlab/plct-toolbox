#!/bin/bash
set -ex
. /etc/profile

RVHOME=/opt/riscv32

cd jdk11u

cd nodebug_32/jvm/openjdk-11.0.9-internal/bin
/opt/riscv32/bin/qemu-riscv32 -L ${RVHOME}/sysroot ./java -version
#/opt/riscv32/bin/qemu-riscv32 -L ${RVHOME}/sysroot ./java -XX:+TraceBytecodes  -version
