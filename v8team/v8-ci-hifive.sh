#!/bin/bash

# For V8 for RISCV project use.
# Please read all the codes before you run it.

# Replace URL
if [ -z "$V8_URL" ]; then
  echo "Usage: V8_URL=your-build-url $0"
  exit 1
fi

D8_HASH_FILE="$PWD/_d8_hashs"

post_to_slack () {
  echo TODO
}

# arg 1: d8 folder
# arg 2: benchmark name
# arg 3: logfile
run_js_test_hifive () {
  python2 ./tools/run-tests.py \
    -j 1 \
    --outdir="$1" \
    -p verbose --report \
    "$2" 2>&1 | tee "$3"
}


# arg 1: d8 path
# arg 2: benchmark name
# arg 3: logfile
run_js_bench_hifive () {
  python2 ./test/benchmarks/csuite/csuite.py \
    -r 1 \
    "$2" \
    baseline \
    "$1/d8" \
    2>&1 | tee "$3"
}

[ -d ./test ]  || rsync -a --delete "$V8_URL/test/" ./test/
[ -d ./tools ] || rsync -a --delete "$V8_URL/tools/" ./tools/

while true; do
  for buildtype in debug release
  do
    rsync -a --delete "$V8_URL/out/riscv64.native.$buildtype/" ./riscv64.native.$buildtype/
    if [ $? -ne 0 ]; then
      echo "ERROR: rsync faild"
      exit 1
    fi

    d8="$PWD/riscv64.native.$buildtype/d8"
    if [ ! -f "$d8" ]; then
      echo "ERROR: Could not find d8 in << $d8 >>"
      exit 2
    fi

    curr_hash=`md5sum "$d8" | cut -f1 -d' '`

    if `grep -q "$curr_hash" $D8_HASH_FILE` ; then
      echo "INFO: current version $curr_hash has been checked. SKIP"
      continue
    fi

    LOG_FILE="$PWD/log.${curr_hash}"

    for test_set in cctest unittests wasm-api-tests mjsunit intl message debugger inspector mkgrokdump wasm-js wasm-spec-tests
    do
      run_js_test_hifive riscv64.native.$buildtype   "$test_set" "$LOG_FILE.$buildtype.$test_set"
    done

    # INFO: release build might hang. remove/disable the hang run.
    for bench in kraken octane sunspider
    do
      run_js_bench_hifive riscv64.native.$buildtype   "$bench" "$LOG_FILE.$buildtype.$bench"
    done

  done # for buildtype in debug release
  # use pastebin to share log
  #pastebinit -i "$LOG_FILE" -b paste.ubuntu.com | tee pastebin.log
  #post_to_slack pastebin.log
  echo "[`date`] Build Finished. Sleep 60 minutes..."
  echo "    scp `hostname`:$LOG_FILE ./"
  echo "$curr_hash" >> $D8_HASH_FILE

  sleep 3600
done
