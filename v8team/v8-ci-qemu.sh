#!/bin/bash

# For V8 for RISCV project use.
# Please read all the codes before you run it.

V8_ROOT="$PWD"
last_build="NULL"
QEMU_SSH_PORT=3333

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
    "$1" \
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

while true; do
  cd "$V8_ROOT"/v8
  git fetch --all
  # the diffault branch is 'riscv64' but you can run this script
  # on any branch you wnt.
  # If you want the bot to focus on specific branch, then use reset (e.g.)
  #git reset --hard riscv/riscv-porting-dev
  git pull

  curr_id=`git log -1 | grep commit | head -n 1 | cut -f2 -d' '`
  echo "$curr_id"

  [ x"$last_build" = x"$curr_id" ] && sleep 600 && continue

  LOG_FILE="$V8_ROOT/log.${curr_id}"

  # clean the log file
  git log -1 > "$LOG_FILE"

  sed -i 's,riscv64-linux-gnu,riscv64-unknown-linux-gnu,' \
      "$V8_ROOT"/v8/build/toolchain/linux/BUILD.gn

  cd "$V8_ROOT/v8"

  run_all_sim_build_checks 2>&1 | tee "$LOG_FILE.simbuild"

  gn gen out/riscv64.native.release \
      --args='is_component_build=false
      is_debug=false
      target_cpu="riscv64"
      v8_target_cpu="riscv64"
      use_goma=false
      goma_dir="None"
      symbol_level = 0'

  ninja -C out/riscv64.native.release -j $(nproc) -v | tee -a "${LOG_FILE}"

  if [ $? -ne 0 ]; then
    echo "ERROR: build failed" | tee -a "$LOG_FILE"
    last_build="$curr_id"
    # Do not write the curr_id to file so we has chanse to rerun the last failure.
    continue
  fi

  gn gen out/riscv64.native.debug \
      --args='is_component_build=false
      is_debug=true
      target_cpu="riscv64"
      v8_target_cpu="riscv64"
      use_goma=false
      goma_dir="None"
      symbol_level = 0'

  ninja -C out/riscv64.native.debug -j $(nproc) -v | tee -a "${LOG_FILE}"

  if [ $? -ne 0 ]; then
    echo "ERROR: build failed" | tee -a "$LOG_FILE"
    last_build="$curr_id"
    # Do not write the curr_id to file so we has chanse to rerun the last failure.
    continue
  fi

  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/out/riscv64.native.debug root@localhost:~/riscv64.native.debug/

  if [ $? -ne 0 ]; then
     echo "ERROR: sync to QEMU/Fedora failed" | tee -a "$LOG_FILE"
    last_build="$curr_id"
    # Do not write the curr_id to file so we has chanse to rerun the last failure.
    continue
  fi
  for test_set in cctest unittests wasm-api-tests mjsunit intl message debugger inspector mkgrokdump
  do
    run_js_test riscv64.native.debug "$test_set" "$LOG_FILE.$test_set"
  done
  run_js_bench riscv64.native.debug/d8 sunspider "$LOG_FILE.sunsipder"
  run_js_bench riscv64.native.debug/d8 kraken "$LOG_FILE.kraken"
  run_js_bench riscv64.native.debug/d8 octane "$LOG_FILE.octane"

  # use pastebin to share log
  pastebinit -i "$LOG_FILE" | tee pastebin.log
  post_to_slack pastebin.log
  echo "[`date`] Build Finished. Sleep 10 minutes..."
  echo "    scp `hostname`:$LOG_FILE ./"

  # Only update commit bookkeeping file after succeed
  last_build="$curr_id"
  echo "$curr_id" > $LAST_ID_FILE

  sleep 600
done
