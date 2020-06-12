#!/bin/bash

# READ:
# https://zhuanlan.zhihu.com/p/141713099

# MIRROR / Snapshots:
# http://mirror.iscas.ac.cn/plct/

git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow
cd OpenROAD-flow
git checkout -b openroad origin/openroad
./build_openroad.sh

