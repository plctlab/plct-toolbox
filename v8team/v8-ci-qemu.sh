#!/bin/bash

# For V8 for RISCV project use.
# Please read all the codes before you run it.

[ -z "$V8_ROOT" ] && V8_ROOT="$PWD"
[ -z "$last_build" ] && last_build="NULL"
[ -z "$QEMU_SSH_PORT" ] && QEMU_SSH_PORT=3333

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
run_js_test_qemu () {
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
run_js_bench_qemu () {
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
  ARGS="-p verbose --report --outdir=$1"
  SUFFIX=""
  BTYPE="${1##*riscv64.sim.}"
  while [ $# -ge 2 ]; do
    [ x$2 = x"stress" ] && ARGS="$ARGS --variants=stress" && SUFFIX="$SUFFIX.stress"
    # FIXME: pass jitless to run-test.py would cause error.
    [ x$2 = x"jitless" ] && ARGS="$ARGS --jitless" && SUFFIX="$SUFFIX.jitless"
    shift
  done

  for t in cctest unittests wasm-api-tests wasm-js mjsunit intl message debugger inspector mkgrokdump wasm-spec-tests fuzzer
  do
    ./tools/run-tests.py $ARGS $t 2>&1 | tee "$LOG_FILE.simbuild.$BTYPE.${t}${SUFFIX}"
    [ x"0" = x"$?" ] || echo "ERROR: sim build has errors: test $t $ARGS" | tee -a "$LOG_FILE.error"
  done
}

run_x86_build_checks () {
  cd "$V8_ROOT/v8"
  tools/dev/gm.py x64.release.check
  if [ $? -ne 0 ]; then
    echo "ERROR: run_x86_build_checks build failed" | tee -a "$LOG_FILE.error"
    HAS_ERROR=1
    exit 2
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
    goma_dir="None"' && \
  ninja -C out/riscv64.sim.debug -j $(nproc) || exit 3
  run_sim_test out/riscv64.sim.debug 2>&1 | tee "$LOG_FILE.sim.debug"
  run_sim_test out/riscv64.sim.debug stress 2>&1 | tee "$LOG_FILE.sim.debug.stress"
  #run_sim_test out/riscv64.sim.debug jitless

  # build simulator config
  # FIXME: temp disable warn as error due to https://github.com/v8-riscv/v8/issues/217
  gn gen out/riscv64.sim.release \
    --args='is_component_build=false
    is_debug=false
    target_cpu="x64"
    v8_target_cpu="riscv64"
    use_goma=false
    treat_warnings_as_errors=false
    goma_dir="None"' && \
  ninja -C out/riscv64.sim.release -j $(nproc) || exit 4
  run_sim_test out/riscv64.sim.release 2>&1 | tee "$LOG_FILE.sim.release"
  run_sim_test out/riscv64.sim.release stress 2>&1 | tee "$LOG_FILE.sim.release.stress"
  #run_sim_test out/riscv64.sim.release jitless

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
  && ninja -C out/riscv64.native.release -j $(nproc) || exit 5

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
  && ninja -C out/riscv64.native.debug -j $(nproc) || exit 6

  if [ $? -ne 0 ]; then
    echo "ERROR: build failed" | tee -a "$LOG_FILE.error"
    HAS_ERROR=1
  fi

}

run_on_qemu () {
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/out/riscv64.native.debug/ root@localhost:~/riscv64.native.debug/ && \
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/out/riscv64.native.release/ root@localhost:~/riscv64.native.release/ && \
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/tools/ root@localhost:~/tools/ && \
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/test/ root@localhost:~/test/

  if [ $? -ne 0 ]; then
    echo "ERROR: sync to QEMU/Fedora failed" | tee -a "$LOG_FILE.error"
    # Do not write the curr_id to file so we has chanse to rerun the last failure.
    HAS_ERROR=1
    return
  fi

  for test_set in cctest unittests wasm-api-tests mjsunit intl message debugger inspector mkgrokdump wasm-js wasm-spec-tests
  do
    run_js_test_qemu riscv64.native.debug   "$test_set" "$LOG_FILE.debug.$test_set"
    run_js_test_qemu riscv64.native.release "$test_set" "$LOG_FILE.release.$test_set"
  done

  for bench in kraken octane sunspider
  do
    run_js_bench_qemu riscv64.native.debug   "$bench" "$LOG_FILE.debug.$bench"
    # FIXME: release build would hang in sunspider benchmark in QEMU.
    [ x"$bench" = x"sunspider" ] || \
        run_js_bench_qemu riscv64.native.release "$bench" "$LOG_FILE.release.$bench"
  done

}

while true; do
  HAS_ERROR=0
  cd "$V8_ROOT"/v8
  git fetch --all
  # the diffault branch is 'riscv64' but you can run this script
  # on any branch you wnt.
  # If you want the bot to focus on specific branch, then use reset (e.g.)
  #git reset --hard riscv/riscv-porting-dev
  git pull
  # if some strange build errors occured, run gclient sync.
  #gclient sync

  curr_id=`git log -1 | grep commit | head -n 1 | cut -f2 -d' '`
  echo "$curr_id"

  if [ x"$last_build" = x"$curr_id" ]; then
    echo "repo has not updated since last build. sleep 1 hour."
    sleep 3600
    continue
  fi

  LOG_FILE="$V8_ROOT/logs/log.${curr_id}"
  [ -d "$V8_ROOT/logs/" ] || mkdir -p "$V8_ROOT/logs/" || exit 2

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

  run_on_qemu 2>&1 | tee "$LOG_FILE.qemu"
  [ x"0" = x"$HAS_ERROR" ] || continue

  # TODO: currently we have multiple log files.
  # How to upload the necessary files?
  # use pastebin to share log
  # pastebinit -i "$LOG_FILE" | tee pastebin.log

  # TODO: Enable slack notification
  # post_to_slack pastebin.log
  echo "CI for $curr_id Finished. Sleep 1 hour."
  echo "if you want to copy logs:"
  echo
  echo "scp `hostname`:${LOG_FILE}* ./"

  # Only update commit bookkeeping file after succeed
  last_build="$curr_id"
  echo "$curr_id" > $LAST_ID_FILE

  sleep 3600
done
