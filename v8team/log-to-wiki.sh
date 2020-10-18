#!/bin/bash

#cat > log2wiki.sh << "EOF"
TEST_LIST="cctest unittests mjsunit wasm-spec-tests wasm-js wasm-api-tests intl message inspector mkgrokdump debugger"

if [ -z "SHA_ID" ]; then
  echo "usage: SHA_ID=commitid $0"
  exit 1
fi

function analyze_logs () {
  [ $# -ge 1 ] || exit 2
  PREFIX="$1"
  [ $# -ge 2 ] && SUFFIX="$2" || SUFFIX=""
  echo "WIKI $PREFIX $SUFFIX"
  for t in $TEST_LIST; do
    f="$PREFIX.$t"
    [ -z "$SUFFIX" ] || f="$f.$SUFFIX"

    tail "$f"
    echo "========= $f =========>"
    n_fail="0"
    tail "$f" | grep '^===' | grep -q 'All tests succeeded' || \
    n_fail=`tail "$f" | grep '^===' | grep 'failed' | cut -f2 -d' '`
    n_run=`tail "$f" | grep '^>>>' | grep 'ran' | cut -f2 -d' '`
    url_log=`pastebinit $f 2>&1`
    #url_log="pastebinit_$f"
    echo "WIKI | $t | +${n_run} / -${n_fail} | [log]($url_log) |"
  done
}

# TODO the cross hifive debug/relase should follow the same script.
# analyze_logs log.$SHA_ID.hifive.debug
# analyze_logs log.$SHA_ID.hifive.release

analyze_logs log.$SHA_ID.debug

analyze_logs log.$SHA_ID.release

analyze_logs log.$SHA_ID.simbuild.debug
analyze_logs log.$SHA_ID.simbuild.debug stress

analyze_logs log.$SHA_ID.simbuild.release
analyze_logs log.$SHA_ID.simbuild.release stress

#EOF

#SHA_ID=5f073e89544266f74697cffec65de65a30c2db3e bash log2wiki.sh | grep WIKI
