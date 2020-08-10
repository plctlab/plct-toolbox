#!/bin/bash

# For V8 for RISCV project use.
# Please read all the codes before you run it.

V8_ROOT="$PWD"
last_build="NULL"

# ensure there are depot_tools in your path
PATH="$V8_ROOT/depot_tools:$PATH"
# ensure you have built riscv-gnu-toolchain
PATH="$PATH:/opt/riscv/bin"
#PATH="$PATH:$HOME/opt/riscv/bin"

LAST_ID_FILE="$V8_ROOT/_last_build_id"

[ -f "$LAST_ID_FILE" ] && last_build=`cat "$LAST_ID_FILE"`

while true; do
  cd "$V8_ROOT"/v8
  git fetch --all
  git reset --hard riscv/riscv-porting-dev

  curr_id=`git log -1 | grep commit | head -n 1 | cut -f2 -d' '`
  echo "$curr_id"

  [ x"$last_build" = x"$curr_id" ] && sleep 600 && continue

  LOG_FILE="$V8_ROOT/log.${curr_id}.txt"

  sed -i 's,riscv64-linux-gnu,riscv64-unknown-linux-gnu,' \
      "$V8_ROOT"/v8/build/toolchain/linux/BUILD.gn

  cd "$V8_ROOT/v8"
  gn gen out/riscv64.native.debug \
      --args='is_component_build=false
      is_debug=true
      target_cpu="riscv64"
      v8_target_cpu="riscv64"
      use_goma=false
      goma_dir="None"
      treat_warnings_as_errors=false
      symbol_level = 0'

  ninja -C out/riscv64.native.debug -j $(nproc)

  #scp -r -P 3333 $V8_ROOT/v8/out/riscv64.native.debug $V8_ROOT/v8/tools $V8_ROOT/v8/test root@localhost:~/"

  rsync -a --delete -e "ssh -p 3333" "$V8_ROOT"/v8/out/riscv64.native.debug root@localhost:~/riscv64.native.debug/

  ssh -p 3333 root@localhost python2 ./tools/run-tests.py --outdir=riscv64.native.debug -p verbose --report cctest unittests wasm-api-tests mjsunit intl message debugger inspector mkgrokdump 2>&1 | tee "$LOG_FILE"

  echo "Build Finished. Log file is at $LOG_FILE"
  echo "    scp `hostname`:$LOG_FILE ./"
  echo "`date` | sleep 10 minutes..."

  # Only update commit bookkeeping file after succeed
  last_build="$curr_id"
  echo "$curr_id" > $LAST_ID_FILE

  sleep 600
done
