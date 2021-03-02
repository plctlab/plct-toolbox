RV64_BIN="$PWD/obj-rv64"

git submodule update --init

# Temp Fix. See:
#    https://github.com/riscv/riscv-gnu-toolchain/issues/736
cd qemu
git checkout master
git pull
git submodule update --init --recursive
cd ..
# End of temp fix

./configure --prefix="$RV64_BIN"
make linux -j $(nproc)

make report-linux  -j $(nproc) SIM=qemu # Run with qemu

