#!/bin/bash

# CATUION: WIP Script. not working yet.

function die () {
  echo "$*"
  exit 9
}

# if [ -z "$GITHUB_TOKEN" ]; then
#   echo "Usage GITHUB_TOKEN=xxxxxxxx SLACK_URL=xxxxxxxx $0"
#   exit 1
# fi

if [ -z "$SLACK_URL" ]; then
  echo "Usage SLACK_URL=xxxxxxxx $0"
  exit 1
fi

if [ -z "$V8_REPO" ]; then
  V8_REPO="$PWD"
  [ -d "$V8_REPO/v8" ] && V8_REPO="$V8_REPO/v8"
fi

LOG_FILE="log.SHA"
WORK_LIST="$V8_REPO/_workdone.list"
touch "${WORK_LIST}"

###################################
# STEP 3: manage to download the pulls
###################################


function prepare_pr_branch () {
  cd $V8_REPO

  # this script suppose v8-riscv/v8 is named 'riscv' remote.
  grep -q -F '+refs/pull/*/head:refs/remotes/riscv/pr/*' .git/config \
  || git config --add remote.riscv.fetch '+refs/pull/*/head:refs/remotes/riscv/pr/*'

  git fetch -v --all

  git checkout pr/$1 || die "git checkout pr/$1 failed."
  git reset --hard $sha || die "git reset to $sha failed"
}

function post_to_slack () {
  # TODO: use color to signify success (green) or failure (red)
  curl -X POST \
    --data-urlencode "payload={\"channel\": \"#github-alerts\",
      \"username\": \"v8-ci-bot\",
      \"text\": \"${pr} $sha has beed built & tested: reusult is at: URLLINK\",
      \"icon_emoji\": \":ghost:\"}" \
      "${SLACK_URL}"
}

function sim_debug_build () {
  gn gen out/riscv64.sim.debug \
    --args='is_component_build=false
    is_debug=true
    target_cpu="x64"
    v8_target_cpu="riscv64"
    use_goma=false
    goma_dir="None"' && \
  ninja -C out/riscv64.sim.debug -j $(nproc) || exit 3

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

function sim_debug_test () {
  run_sim_test out/riscv64.sim.debug 2>&1 | tee "$LOG_FILE.sim.debug"
  # stress tests takes long time heyond a PR has to burden.
  #run_sim_test out/riscv64.sim.debug stress 2>&1 | tee "$LOG_FILE.sim.debug.stress"
}
###################################
# STEP 4: build locally using docker or shell
###################################
function do_ci () {
  pr="$1"
  sha="$2"
  LOG_FILE="log.${sha}"

  cd "${V8_REPO}"

  prepare_pr_branch ${pr} $sha
  #----------------------------------
  # 4.1 sim debug build & check
  #----------------------------------
  sim_debug_build
  sim_debug_test

  #----------------------------------
  # 4.2 sim release build w/o tests
  #----------------------------------
  # FIXME: release build has now ~25 failures.
  # Disable it temporiorally.
  #sim_release_build
  # TODO: Enable sim_release_test after all bugs fixed.
  # sim_release_test

  #----------------------------------
  # 4.3 cross debug build w/ tests
  #----------------------------------
  #cross_debug_build
  # cross_debug_test

  #----------------------------------
  # 4.4 cross release build w/o tests
  #----------------------------------
  #cross_release_build
  # cross_release_test

  ###################################
  # STEP 5: send back the testing results.
  ###################################
  post_to_slack ${pr} $sha

  # after all works done, put the SHA to bookkeeping file.
  echo $sha >> "${WORK_LIST}"
}

###################################
# STEP 2: filter the pulls list, get open and reviewed pulls
###################################
# $ cat pr-sha.txt | while read u; do read sha; echo $u -- $sha; done
# https://api.github.com/repos/v8-riscv/v8/pulls/222 -- a84baaf245b8fd4e2736976c6a0b3b994b8c6b36
# https://api.github.com/repos/v8-riscv/v8/pulls/221 -- e5207309dc1f650b44567a57fe630553b7452a89
function do_ci_if_approved () {
  pr="${1##*/}"
  sha="$2"

  # Get the info of a specific PR.
  # there are review comments fields in the json the webapi returns.
  # use temp file reviews.{pr} for debugging.
  curl \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/v8-riscv/v8/pulls/${pr}/reviews \
    | jq '.[] | select(.state=="APPROVED")' > reviews."${pr}"
  has_approved=`wc -l reviews."${pr}" | cut -f1 -d' '`
  echo "DEBUG: xx $has_approved xx"
  if [ x"$has_approved" = x"0" ]; then
    echo "PR ${pr} with $sha has not been approved yet. skip."
    return
  else
    # otherwise we nned to build it.
    do_ci ${pr} $sha
  fi


}

###################################
# STEP 1: get all pull requests
###################################
# https://docs.github.com/en/rest/overview/resources-in-the-rest-api
# $ curl -H "Authorization: token OAUTH-TOKEN" https://api.github.com
function pull_open_prs () {

  # save it to to a temp file for debug purpose
  curl \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/v8-riscv/v8/pulls \
    > _v8-open-pulls.json

  # Use jq to extract json elements. the output format is like:
  #

  cat _v8-open-pulls.json | jq -r '.[] | .url,.head.sha' | tee _pr-sha.txt

}

while true; do
  # pull all open PRs, get all #pr and #SHA pairs.
  cd ${V8_REPO}
  pull_open_prs

  # if SHA has been built, skip it. If it is first time seen, build it.
  # Use SHA instead of #PR, so everytime PR branch has updated the script
  # could get noticed and rebuild the PR.
  cat _pr-sha.txt | while read u; do
    read sha
    if [ x"$sha" = x"" ]; then
      echo "ERROR Read SHA failed: #pr = $u, sha = $sha"
      break
    fi
    grep -q "$sha" "${WORK_LIST}" || do_ci_if_approved "$u" "$sha"
  done

  # sleep 5 minutes. be gentle to github.
  sleep 300
done



