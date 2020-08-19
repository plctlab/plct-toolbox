#!/bin/bash

# For V8 for RISCV project use.
# Please read all the codes before you run it.

last_hash="NULL"

# Replace URL
V8_URL="user@localhost:path/to/v8/"
D8_URL="$V8_URL/out/riscv64.native.debug/"

LAST_ID_FILE="$HOME/_v8_last_build_hash"

post_to_slack () {
  echo TODO
}


[ -f "$LAST_ID_FILE" ] && last_hash=`cat "$LAST_ID_FILE"`

[ -d ./test ]  || rsync -a --delete "$V8_URL/test/" ./test/
[ -d ./tools ] || rsync -a --delete "$V8_URL/tools/" ./tools/

while true; do

  rsync -a --delete "$D8_URL" ./riscv64.native.debug/

  if [ $? -ne 0 ]; then
    echo "ERROR: rsync faild"
    sleep 3600
    continue
  fi

  d8="$PWD/riscv64.native.debug/d8"

  if [ ! -f "$d8" ]; then
    echo "ERROR: Could not find d8 in << $d8 >>"
    sleep 3600
    continue
  fi

  curr_hash=`md5sum "$d8" | cut -f1 -d' '`

  if [ x"$last_hash" = x"$curr_hash" ]; then
    echo "INFO: current version $curr_hash has been checked. SKIP"
    sleep 3600
    continue
  fi

  LOG_FILE="$PWD/log.${curr_hash}.txt"

  python2 ./tools/run-tests.py -j 3 \
    --outdir=riscv64.native.debug \
    -p verbose --report \
    cctest \
    unittests \
    wasm-api-tests \
    mjsunit \
    intl \
    message \
    debugger \
    inspector \
    mkgrokdump 2>&1 | tee "$LOG_FILE"

  python2 test/benchmarks/csuite/csuite.py \
    -r 1 \
    sunspider \
    baseline \
    riscv64.native.debug/d8 \
    | tee -a "LOG_FILE"

  python2 test/benchmarks/csuite/csuite.py \
    -r 1 \
    kraken \
    baseline \
    riscv64.native.debug/d8 \
    | tee -a "LOG_FILE"

  python2 test/benchmarks/csuite/csuite.py \
    -r 1 \
    octane \
    baseline \
    riscv64.native.debug/d8 \
    | tee -a "LOG_FILE"
  # use pastebin to share log
  pastebinit -i "$LOG_FILE" -b paste.ubuntu.com | tee pastebin.log
  post_to_slack pastebin.log
  echo "[`date`] Build Finished. Sleep 10 minutes..."
  echo "    scp `hostname`:$LOG_FILE ./"

  # Only update commit bookkeeping file after succeed
  echo "$curr_hash" > $LAST_ID_FILE
  last_hash="$curr_hash"

  sleep 3600
done
