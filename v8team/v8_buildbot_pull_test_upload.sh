#!/bin/bash

# For V8 for RISCV project use.
# Please read all the codes before you run it.

last_hash="NULL"

# Replace URL
V8_URL="user@localhost:path/to/v8/"
D8_URL="$V8_URL/out/riscv64.native.debug/"

LAST_ID_FILE="$HOME/_v8_last_build_hash"

[ -f "$LAST_ID_FILE" ] && last_hash=`cat "$LAST_ID_FILE"`

[ -d ./test ]  || rsync -a --delete "$V8_URL/test/" ./test/
[ -d ./tools ] || rsync -a --delete "$V8_URL/tools/" ./tools/

while true; do

  rsync -a --delete "$D8_URL" ./riscv64.native.debug/

  d8="$PWD/riscv64.native.debug/d8"

  curr_hash=`md5sum "$d8" | cut -f1 -d' '`

  echo $curr_hash

  [ x"$last_hash" = x"$curr_hash" ] && sleep 3600 && continue

  LOG_FILE="$PWD/log.${curr_hash}.txt"

  python2 ./tools/run-tests.py \
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

  echo "Build Finished. Log file is at $LOG_FILE"
  echo "    scp `hostname`:$LOG_FILE ./"
  echo "`date` | sleep 10 minutes..."

  # Only update commit bookkeeping file after succeed
  echo "$curr_hash" > $LAST_ID_FILE
  last_hash="$curr_hash"

  sleep 3600
done
