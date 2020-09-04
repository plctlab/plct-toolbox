#!/bin/bash

# For V8 for RISCV project use.
# Please read all the codes before you run it.

# Replace URL
[ -z "$V8_URL" ] && V8_URL="user@localhost:path/to/v8/"
D8_DBG_URL="$V8_URL/out/riscv64.native.debug/"
D8_RLS_URL="$V8_URL/out/riscv64.native.release/"

last_hash="NULL"
LAST_ID_FILE="$HOME/_v8_last_build_hash"

post_to_slack () {
  echo TODO
}


# arg 1: d8 folder
# arg 2: benchmark name
# arg 3: logfile
run_js_test_hifive () {
  python2 ./tools/run-tests.py \
    -j 2 \
    --outdir="$1" \
    -p verbose --report \
    "$2" 2>&1 | tee "$3"
}


# arg 1: d8 path
# arg 2: benchmark name
# arg 3: logfile
run_js_bench_hifive () {
  python2 test/benchmarks/csuite/csuite.py \
    -r 1 \
    "$2" \
    baseline \
    "$1/d8" \
    2>&1 | tee "$3"
}

[ -f "$LAST_ID_FILE" ] && last_hash=`cat "$LAST_ID_FILE"`

[ -d ./test ]  || rsync -a --delete "$V8_URL/test/" ./test/
[ -d ./tools ] || rsync -a --delete "$V8_URL/tools/" ./tools/

while true; do
  rsync -a --delete "$D8_DBG_URL" ./riscv64.native.debug/
  if [ $? -ne 0 ]; then
    echo "ERROR: rsync faild"
    sleep 3600
    continue
  fi

  rsync -a --delete "$D8_RLS_URL" ./riscv64.native.release/
  if [ $? -ne 0 ]; then
    echo "ERROR: rsync faild"
    sleep 3600
    continue
  fi

  d8dbg="$PWD/riscv64.native.debug/d8"
  if [ ! -f "$d8dbg" ]; then
    echo "ERROR: Could not find d8 in << $d8dbg >>"
    sleep 3600
    continue
  fi

  d8rls="$PWD/riscv64.native.release/d8"
  if [ ! -f "$d8rls" ]; then
    echo "ERROR: Could not find d8 in << $d8rls >>"
    sleep 3600
    continue
  fi

  # use dbg hash for both dbg and release.
  curr_hash=`md5sum "$d8dbg" | cut -f1 -d' '`

  if [ x"$last_hash" = x"$curr_hash" ]; then
    echo "INFO: current version $curr_hash has been checked. SKIP"
    sleep 3600
    continue
  fi

  LOG_FILE="$PWD/log.${curr_hash}"

  for test_set in cctest unittests wasm-api-tests mjsunit intl message debugger inspector mkgrokdump wasm-js wasm-spec-tests
  do
    run_js_test_hifive riscv64.native.debug   "$test_set" "$LOG_FILE.debug.$test_set"
    run_js_test_hifive riscv64.native.release "$test_set" "$LOG_FILE.release.$test_set"
  done

  for bench in kraken octane sunspider
  do
    run_js_bench_hifive riscv64.native.debug   "$bench" "$LOG_FILE.debug.$bench"
    # FIXME: release build would hang in sunspider benchmark in QEMU.
    [ x"$bench" = x"sunspider" ] || \
        run_js_bench_hifive riscv64.native.release "$bench" "$LOG_FILE.release.$bench"
  done

  # use pastebin to share log
  #pastebinit -i "$LOG_FILE" -b paste.ubuntu.com | tee pastebin.log
  #post_to_slack pastebin.log
  echo "[`date`] Build Finished. Sleep 60 minutes..."
  echo "    scp `hostname`:$LOG_FILE ./"

  # Only update commit bookkeeping file after succeed
  echo "$curr_hash" > $LAST_ID_FILE
  last_hash="$curr_hash"

  sleep 3600
done
