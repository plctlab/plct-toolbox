#!/bin/bash

# maintainer lazyparser
# last update: 20200624

die () {
	echo "$*"
	exit 3
}

ensure_file () {
	[ $# -eq 1 ] || die "ensure_file need ONE arg"
	filename=${1##*/}
	[ -f "${filename}" ] || wget "$1" -O "${filename}"
}

ensure_file https://mirror.iscas.ac.cn/plct/Fedora-Developer-Rawhide-20191123.n.0-fw_payload-uboot-qemu-virt-smode.elf
ensure_file https://mirror.iscas.ac.cn/plct/Fedora-Developer-Rawhide-20191123.n.0-sda.raw.xz

[ -f Fedora-Developer-Rawhide-20191123.n.0-sda.raw.xz ] || die "Need Fedora-Developer-Rawhide-20191123.n.0-sda.raw.xz"
[ -f Fedora-Developer-Rawhide-20191123.n.0-fw_payload-uboot-qemu-virt-smode.elf ] || die "Need Fedora-Developer-Rawhide-20191123.n.0-fw_payload-uboot-qemu-virt-smode.elf"
# better to keep an original image.
unxz -k Fedora-Developer-Rawhide-20191123.n.0-sda.raw.xz

echo 'Make sure you have QEMU (≥ 5.0.0)'
echo 'try to locate: qemu-system-riscv64'
echo
which qemu-system-riscv64
echo
echo 'If you do not have it yet. compile it.'
echo
echo 'If clone is hard, try snahpshot:'
echo '    wget https://mirror.iscas.ac.cn/plct/qemu.20200613.tar.bz2'
echo '    tar xf qemu.20200613.tar.bz2'
echo '    cd qemu'
echo '    ./configure --target-list=riscv64-softmmu && make -j 4'
echo '    sudo make install # if you want. Optional.'
echo
echo

echo 'Press ENTER after you have qemu-system-riscv64'
read

echo 'All set. A few tips:'
echo
echo '1. Press **Ctrl-A x** to quit qemu :)'
echo '2. Open a new terminal, use "ssh -p 3333 root@localhost"'
echo '3. If you encountered "wrong password" issue, copy your pubkey in /root/.ssh/authorized_keys'
echo '   and make sure "chmod 700 .ssh; chmod 600 .ssh/authorized_keys'
echo '4. use "scp -P 3333 your-file-want-to-copy-into root@localhost:~/" to copy files into/out from.'
echo '5. The ROOT pass changed from "riscv" to "fedora_rocks!"'
echo

echo 'For PLCT V8 team members:'
echo 'You need copy both d8 and snapshot'
echo
echo '    scp -r -P 22022 out/rv64.natived8.debug/snapshot_blob.bin  root@localhost:~/'
echo '    scp -r -P 22022 out/rv64.natived8.debug/d8  root@localhost:~/'
echo
echo 'Now you can happily run ./d8 and see the crash call stack :-P'
echo

echo 'Ready? Press ENTER to start QEMU:'
read

#VER=20200108.n.0
VER=20191123.n.0

qemu-system-riscv64 \
  -nographic \
  -machine virt \
  -smp 4 \
  -m 2G \
  -kernel Fedora-Developer-Rawhide-${VER}-fw_payload-uboot-qemu-virt-smode.elf \
  -object rng-random,filename=/dev/urandom,id=rng0 \
  -device virtio-rng-device,rng=rng0 \
  -device virtio-blk-device,drive=hd0 \
  -drive file=Fedora-Developer-Rawhide-${VER}-sda.raw,format=raw,id=hd0 \
  -device virtio-net-device,netdev=usernet \
  -netdev user,id=usernet,hostfwd=tcp::3333-:22


