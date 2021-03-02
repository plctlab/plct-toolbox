RV64_BIN="$PWD/obj-rv64"

make clean
git submodule pull --init
./configure --prefix="$RV64_BIN"
make linux -j $(nproc)

make report-linux  -j $(nproc) SIM=qemu # Run with qemu

