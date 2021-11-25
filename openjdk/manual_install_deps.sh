#!/bin/bash

set -ex

RVHOME=/opt/riscv32

cd "$RVHOME"

[ -d build_ext_libs_riscv32 ] || mkdir build_ext_libs_riscv32
cd build_ext_libs_riscv32

git clone --depth=1 https://github.com/libffi/libffi

git clone --depth=1 https://github.com/apple/cups

git clone --depth=1 https://github.com/libexpat/libexpat

git clone --depth=1 https://github.com/madler/zlib

git clone --depth=1 https://github.com/glennrp/libpng

wget https://download.savannah.gnu.org/releases/freetype/freetype-2.10.4.tar.gz 
tar -xzvf freetype-2.10.4.tar.gz 
mv freetype-2.10.4 freetype2 
rm -f freetype-2.10.4.tar.gz

git clone -b json-c-0.13 --depth=1 https://github.com/json-c/json-c

git clone --depth=1 https://gitlab.freedesktop.org/fontconfig/fontconfig

git clone --depth=1 https://github.com/alsa-project/alsa-lib

git clone --depth=1 https://github.com/karelzak/util-linux

mkdir xorg && cd xorg && wget https://raw.githubusercontent.com/openjdk-riscv/xorg-util-modular/riscv32/xorg_modules && git clone --depth=1 -b riscv32 https://github.com/openjdk-riscv/xorg-util-modular util/modular

cd ..


