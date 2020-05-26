#!/bin/bash

echo "This script will download multiple files in multiple folders."
echo "It is better to mkdir a new clean folder for me."
echo "Press ENTER to continue, or Ctrl-C to cancel."
read

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PWD/depot_tools:$PATH"

gclient

mkdir v8-cr
cd v8-cr
fetch v8
cd v8

# Important: download huge prebuild binaries
gclient sync

echo "Done. Next, run these command manually:"
echo
echo "./build/install-build-deps.sh"
echo "tools/dev/gm.py x64.release"
echo "tools/dev/gm.py x64.release.check"


