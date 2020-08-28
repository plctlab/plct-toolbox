#!/bin/bash

# For V8 for RISCV project use.
# Please read all the codes before you run it.

V8_ROOT="$PWD"
last_build="NULL"
QEMU_SSH_PORT=3333

# Global flag to pass the sub process return values
HAS_ERROR=0

# ensure there are depot_tools in your path
PATH="$V8_ROOT/depot_tools:$PATH"
# ensure you have built riscv-gnu-toolchain
PATH="$PATH:/opt/riscv/bin"
#PATH="$PATH:$HOME/opt/riscv/bin"

LAST_ID_FILE="$V8_ROOT/_last_build_id"

[ -f "$LAST_ID_FILE" ] && last_build=`cat "$LAST_ID_FILE"`

post_to_slack () {
  echo TODO
}

# arg 1: d8 folder
# arg 2: benchmark name
# arg 3: logfile
run_js_test () {
  ssh -p $QEMU_SSH_PORT root@localhost python2 \
    ./tools/run-tests.py \
    -j 8 \
    --outdir="$1" \
    -p verbose --report \
    "$2" 2>&1 | tee "$3"
}

# arg 1: d8 path
# arg 2: benchmark name
# arg 3: logfile
run_js_bench () {
  ssh -p $QEMU_SSH_PORT root@localhost python2 test/benchmarks/csuite/csuite.py \
    -r 1 \
    "$2" \
    baseline \
    "$1/d8" \
    2>&1 | tee "$3"
}

# Copied from v8-riscv-tools/run-tests.py
# suppose it is in the v8 folder
# arg 1: outdir
# arg 2: extra args for run-tests.py
run_sim_test () {
  ARGS="-p verbose --report"
  [ x$2 = x"stress" ] && ARGS="$ARGS --variants=stress"

  ./tools/run-tests.py $ARGS --outdir=$1 cctest
  ./tools/run-tests.py $ARGS --outdir=$1 unittests
  ./tools/run-tests.py $ARGS --outdir=$1 wasm-api-tests wasm-js
  ./tools/run-tests.py $ARGS --outdir=$1 mjsunit
  ./tools/run-tests.py $ARGS --outdir=$1 intl message debugger inspector mkgrokdump
  ./tools/run-tests.py $ARGS --outdir=$1 wasm-spec-tests
  ./tools/run-tests.py $ARGS --outdir=$1 fuzzer
}

run_x86_build_checks () {
  cd "$V8_ROOT/v8"
  tools/dev/gm.py x64.release.check
  if [ $? -ne 0 ]; then
    echo "ERROR: build failed" | tee -a "$LOG_FILE.error"
    HAS_ERROR=1
  fi
}

run_all_sim_build_checks () {
  cd "$V8_ROOT/v8"

  # build simulator config
  gn gen out/riscv64.sim.debug \
    --args='is_component_build=false
    is_debug=true
    target_cpu="x64"
    v8_target_cpu="riscv64"
    use_goma=false
    goma_dir="None"'

  ninja -C out/riscv64.sim.debug -j $(nproc)
  run_sim_test out/riscv64.sim.debug
  run_sim_test out/riscv64.sim.debug stress

  # build simulator config
  gn gen out/riscv64.sim.release \
    --args='is_component_build=false
    is_debug=false
    target_cpu="x64"
    v8_target_cpu="riscv64"
    use_goma=false
    goma_dir="None"'

  ninja -C out/riscv64.sim.release -j $(nproc)
  run_sim_test out/riscv64.sim.release
  run_sim_test out/riscv64.sim.release stress

}

build_cross_builds () {
  cd "$V8_ROOT/v8"
  gn gen out/riscv64.native.release \
      --args='is_component_build=false
      is_debug=false
      target_cpu="riscv64"
      v8_target_cpu="riscv64"
      use_goma=false
      goma_dir="None"
      treat_warnings_as_errors=false
      symbol_level = 0' \
  && ninja -C out/riscv64.native.release -j $(nproc)

  if [ $? -ne 0 ]; then
    echo "ERROR: build failed" | tee -a "$LOG_FILE.error"
    HAS_ERROR=1
  fi

  gn gen out/riscv64.native.debug \
      --args='is_component_build=false
      is_debug=true
      target_cpu="riscv64"
      v8_target_cpu="riscv64"
      use_goma=false
      goma_dir="None"
      treat_warnings_as_errors=false
      symbol_level = 0' \
  && ninja -C out/riscv64.native.debug -j $(nproc)

  if [ $? -ne 0 ]; then
    echo "ERROR: build failed" | tee -a "$LOG_FILE.error"
    HAS_ERROR=1
  fi

}

while true; do
  HAS_ERROR=0
  cd "$V8_ROOT"/v8
  git fetch --all
  # the diffault branch is 'riscv64' but you can run this script
  # on any branch you wnt.
  # If you want the bot to focus on specific branch, then use reset (e.g.)
  #git reset --hard riscv/riscv-porting-dev
  git pull && gclient sync

  curr_id=`git log -1 | grep commit | head -n 1 | cut -f2 -d' '`
  echo "$curr_id"

  [ x"$last_build" = x"$curr_id" ] && sleep 3600 && continue

  LOG_FILE="$V8_ROOT/log.${curr_id}"

  # clean the log file
  git log -1 > "$LOG_FILE"

  sed -i 's,riscv64-linux-gnu,riscv64-unknown-linux-gnu,' \
      "$V8_ROOT"/v8/build/toolchain/linux/BUILD.gn

  cd "$V8_ROOT/v8"

  # run x86 build checl. exit the script if error occurs.
  run_x86_build_checks 2>&1 | tee "$LOG_FILE.x64build"
  [ x"0" = x"$HAS_ERROR" ] || exit 1

  run_all_sim_build_checks 2>&1 | tee "$LOG_FILE.simbuild"
  [ x"0" = x"$HAS_ERROR" ] || continue

  build_cross_builds 2>&1 | tee "$LOG_FILE.crossbuild"
  [ x"0" = x"$HAS_ERROR" ] || continue

  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/out/riscv64.native.debug/ root@localhost:~/riscv64.native.debug/
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/out/riscv64.native.release/ root@localhost:~/riscv64.native.release/
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/tools/ root@localhost:~/tools/
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/test/ root@localhost:~/test/

  if [ $? -ne 0 ]; then
     echo "ERROR: sync to QEMU/Fedora failed" | tee -a "$LOG_FILE.error"
    last_build="$curr_id"
    # Do not write the curr_id to file so we has chanse to rerun the last failure.
    continue
  fi

  for test_set in cctest unittests wasm-api-tests mjsunit intl message debugger inspector mkgrokdump
  do
    run_js_test riscv64.native.debug   "$test_set" "$LOG_FILE.debug.$test_set"
    run_js_test riscv64.native.release "$test_set" "$LOG_FILE.release.$test_set"
  done

  for bench in sunspider kraken octane
  do
    run_js_bench riscv64.native.debug   "$bench" "$LOG_FILE.debug.$bench"
    run_js_bench riscv64.native.release "$bench" "$LOG_FILE.release.$bench"
  done

  # TODO: currently we have multiple log files.
  # How to upload the necessary files?
  # use pastebin to share log
  # pastebinit -i "$LOG_FILE" | tee pastebin.log

  # TODO: Enable slack notification
  # post_to_slack pastebin.log
  echo "[`date`] Build Finished. Sleep 10 minutes..."
  echo "    scp `hostname`:${LOG_FILE}* ./"

  # Only update commit bookkeeping file after succeed
  last_build="$curr_id"
  echo "$curr_id" > $LAST_ID_FILE

  sleep 3600
done
