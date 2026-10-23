#!/bin/zsh
# Usage: capture_take.sh <name> "<trailer config, e.g. shot=match stake=500 deck=royal_crimson>" [outdir]
# Needs the trailer build installed on the booted simulator:
#   flutter build ios --simulator --debug --dart-define-from-file=flavors/dev.json --dart-define=TRAILER_SHOT=match
set -u
NAME=$1; CFG=$2; OUT=${3:-$(dirname $0)/takes}
BUNDLE=com.hailsom.shadowhand
mkdir -p $OUT
OUT=$(cd $OUT && pwd)
DATA=$(xcrun simctl get_app_container booted $BUNDLE data)
mkdir -p $DATA/Documents && print -r -- "$CFG" > $DATA/Documents/trailer.txt
xcrun simctl terminate booted $BUNDLE 2>/dev/null
xcrun simctl io booted recordVideo --codec=h264 --force $OUT/$NAME.mov &
REC=$!
sleep 1.5
python3 -c 'import time;print(int(time.time()*1000))' > $OUT/$NAME.start
xcrun simctl spawn booted log stream --style compact --predicate 'eventMessage CONTAINS "TRAILER"' > $OUT/$NAME.log 2>&1 &
APP=$!
xcrun simctl launch --terminate-running-process booted $BUNDLE >/dev/null
for i in {1..240}; do grep -q -e "shot-done" -e "TRAILER error" $OUT/$NAME.log 2>/dev/null && break; sleep 0.5; done
sleep 1.5
kill -INT $REC; wait $REC 2>/dev/null
kill $APP 2>/dev/null
grep TRAILER $OUT/$NAME.log
