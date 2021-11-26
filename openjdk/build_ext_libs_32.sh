#!/bin/bash


# exit on error
set -ex

#if [ ! -n "$1" ];then
#    echo "Please designate riscv toolchain path"
#    exit 1
#else
#    riscvpath=$1
#    echo "riscv toolchian path was set as: $riscvpath"
#fi
riscvpath=/opt/riscv32

cd $riscvpath/build_ext_libs_riscv32 || exit 3

export PATH=$riscvpath/bin:$PATH
export sysroot=$riscvpath/sysroot
export prefix=$sysroot/usr

# libffi
cd libffi && ./autogen.sh && ./configure --host=riscv32-unknown-linux-gnu --prefix=$prefix 

make -j $(nproc) && make install

cd -

[ -f $prefix/include/ffi.h ] || exit 4

# cups
cd cups && ./configure --host=riscv32-unknown-linux-gnu --disable-ssl --disable-gssapi --disable-avahi --disable-libusb --disable-dbus --disable-systemd

make -j $(nproc) CFLAGS="-Wno-error=sign-conversion -Wno-error=format-truncation" CXXFLAGS="-Wno-error=sign-conversion -Wno-error=format-truncation" && make install DSTROOT=$sysroot

cd -

# libexpat
cd libexpat/expat && ./buildconf.sh &&./configure --host=riscv32-unknown-linux-gnu --prefix=$prefix

make -j $(nproc) && make install

cd -

# zlib
cd zlib && CHOST=riscv32 CC=riscv32-unknown-linux-gnu-gcc AR=riscv32-unknown-linux-gnu-ar RANLIB=riscv32-unknown-linux-gnu-ranlib ./configure  --prefix=$prefix

make -j $(nproc) && make install

cd -

# libpng
cd libpng && ./configure --host=riscv32-unknown-linux-gnu --prefix=$prefix

make -j $(nproc) && make install

cd -

# freetype2
cd freetype2 && ./autogen.sh && ./configure --host=riscv32-unknown-linux-gnu --prefix=$prefix --with-brotli=no --with-harfbuzz=no --with-bzip2=no

make -j $(nproc) && make install

cd -

# json-c
cd json-c && ./autogen.sh &&  ./configure --host=riscv32-unknown-linux-gnu --prefix=$prefix

make -j $(nproc) && make install

cd -

# fontconfig
cd fontconfig && PKG_CONFIG_PATH=$prefix/lib/pkgconfig ./autogen.sh --host=riscv32-unknown-linux-gnu --prefix=$prefix

make -j $(nproc) && make install

cd -

# alsa-lib
cd alsa-lib && libtoolize --force --copy --automake && aclocal && autoheader && automake --foreign --copy --add-missing && autoconf && ./configure --host=riscv32-unknown-linux-gnu --prefix=$prefix

make -j $(nproc) && make install

cd -

# util-linux
cd util-linux && ./autogen.sh && ./configure --host=riscv32-unknown-linux-gnu --prefix=$prefix --disable-all-programs --enable-libuuid

make -j $(nproc) && make install || true

cd -

# xorg
cd xorg && CONFFLAGS="--host=riscv32-unknown-linux-gnu --disable-malloc0returnsnull" ./util/modular/build.sh --modfile ./xorg_modules --clone $prefix

echo "Success. exit"

