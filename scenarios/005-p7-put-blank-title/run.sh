#!/usr/bin/env bash
# P7: PUT で空のタイトルを送ると 200 が返るか（POST は 400 の対照）
source "$(dirname "$0")/../lib/common.sh"
OUT="$ROOT/results/005/p7-put-blank-title"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
W="$(new_copy)"
cp "$ROOT/scenarios/005-p7-put-blank-title/fixtures/PutBlankTitleProbeTest.java" "$W/presentation/src/test/java/com/example/taskmaster/presentation/"
rc=$(run_logged "$W" "$OUT/probe.log" ./gradlew clean :presentation:test --tests '*PutBlankTitleProbeTest' "${GRADLE_OPTS_COMMON[@]}")
x="$W/presentation/build/test-results/test/TEST-com.example.taskmaster.presentation.PutBlankTitleProbeTest.xml"
[ -f "$x" ] && sanitize "$W" < "$x" > "$OUT/PutBlankTitleProbeTest.xml"
{ echo "rc: $rc"; grep -ho 'PROBE [A-Z_]* status=[0-9]* body=.*' "$OUT/PutBlankTitleProbeTest.xml" 2>/dev/null | sed 's/&quot;/"/g'; } > "$OUT/summary.txt"
rm -rf "$W"; cat "$OUT/summary.txt"
