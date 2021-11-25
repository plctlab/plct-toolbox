#!/bin/bash

# Arg 1: filename
# Arg 2: URL
function ensure_file () {
	if [ -f "$1" ]; then
		echo "FILE: $1 has been downloaded. Skip."
	else
		echo "FILE: $1 had not been downloaded. Downloading"
		wget --no-check-certificate -O "$1" "$2"
	fi
}

ensure_file qemu-5.2.0.tar.xz https://download.qemu.org/qemu-5.2.0.tar.xz
ensure_file riscv-gnu-toolchain.tbz https://mirror.iscas.ac.cn/plct/riscv-gnu-toolchain.20211125.tbz
