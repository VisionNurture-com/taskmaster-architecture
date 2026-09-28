#!/usr/bin/env bash
# M4: TaskServiceTest（Mockito のみ）と、同じ 3 件を Spring のコンテキストで行う版の実行時間を比べる
#   使い方: bash scenarios/004-m4-test-time/run.sh [回数（既定 10）]
source "$(dirname "$0")/../lib/common.sh"
N="${1:-10}"
OUT="$ROOT/results/004/m4-test-time"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
W="$(new_copy)"
cp "$(dirname "$0")/fixtures/TaskServiceSpringContextTest.java" "$W/application/src/test/java/com/example/taskmaster/application/"
awk '{ print } /testImplementation\("org.mockito:mockito-junit-jupiter"\)/ { print "    testImplementation(\"org.springframework:spring-test\")" }' \
  "$W/application/build.gradle.kts" > "$W/application/build.gradle.kts.new" && mv "$W/application/build.gradle.kts.new" "$W/application/build.gradle.kts"
cp "$W/application/build.gradle.kts" "$OUT/application-build.gradle.kts"
python3 "$(dirname "$0")/measure.py" "$W" "$OUT" "$N"
rm -rf "$W"
