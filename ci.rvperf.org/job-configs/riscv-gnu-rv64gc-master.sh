RV64_BIN="$PWD/obj-rv64"

git submodule update --init
./configure --prefix="$RV64_BIN"
make linux -j $(nproc)

make report-linux  -j $(nproc) SIM=qemu # Run with qemu

