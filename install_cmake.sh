#!/bin/bash

set -e

TOP="$PWD"

ensure_cmake () {
  echo "Make sure your cmake version is above 3.13.4:"
  echo "your version is: `cmake --version`"
  echo
  echo "I will download and use the latest sable cmake,"
  echo "Press any key other than enter to skip this step."
  echo "or press ENTER to continue to download & build cmkae."

  read -t 5 -p "You have 5 seconds to refuse, or I'll continue:" cmake_yes || echo "yes"

  if [ -z "$cmake_yes" ]; then
    CMAKE_FILE=cmake-3.18.1.tar.gz
    CMAKE_DIR=${CMAKE_FILE%.tar.gz}
    wget https://github.com/Kitware/CMake/releases/download/v3.18.1/$CMAKE_FILE
    tar xf $CMAKE_FILE
    cd $CMAKE_DIR
    if [ x"$UID" == x"0" ]; then
	    ./configure --parallel=$(nproc)
	    make install -j $(nproc)
    else
	    [ -d "$HOME/bin" ] || mkdir -p "$HOME/bin"
	    ./configure --prefix="$HOME/bin" --parallel=$(nproc)
	    make install -j $(nproc)
	    export PATH="$HOME/bin/bin:$PATH"
	    echo 'export PATH="$HOME/bin/bin:$PATH"' >> $HOME/.bashrc
    fi
  fi
}

ensure_cmake

