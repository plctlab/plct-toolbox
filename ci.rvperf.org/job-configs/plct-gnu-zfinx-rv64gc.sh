git submodule update --init


cd riscv-gcc
git remote | grep -q zfinx || git remote add zfinx https://github.com/pz9115/riscv-gcc.git
git fetch zfinx
git checkout -f zfinx/riscv-gcc-10.2.0-zfinx
cd ..

cd riscv-binutils
git remote | grep -q zfinx || git remote add zfinx https://github.com/pz9115/riscv-binutils-gdb.git
git fetch zfinx
git checkout zfinx/riscv-binutils-2.35-zfinx
cd ..

cd qemu
git remote | grep -q plct-qemu || git remote add plct-qemu https://github.com/isrc-cas/plct-qemu.git || true
git fetch plct-qemu
git checkout plct-qemu/plct-zfinx-dev
git reset --hard d73c46e4a84e47ffc61b8bf7c378b1383e7316b5
cd ..

# for rv64:
./configure --prefix="$PWD/opt-rv64/" --with-arch=rv64gc --with-abi=lp64 --with-multilib-generator="rv64gc-lp64--"

# you can use make -j* to make speed up
make -j $(nproc) check-gcc-newlib
make -j $(nproc) check-binutils-newlib
make report-gcc-newlib
make report-binutils-newlib

