#!/usr/bin/env bash
# P1: 005 掲載の presentation/build.gradle.kts のまま、Testcontainers の版がどう解決されるか・テストが通るか
# P2: Gradle の既定の出力に「… PASSED」の行と「N tests completed」が出るか
REF="${REF:-article-005-as-published}"
source "$(dirname "$0")/../lib/common.sh"
OUT="$ROOT/results/005/p1-p2-as-published"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
W="$(new_copy)"

rcDeps=$(run_logged "$W" "$OUT/testRuntimeClasspath.log" ./gradlew :presentation:dependencies --configuration testRuntimeClasspath "${GRADLE_OPTS_COMMON[@]}")
grep -oE 'org\.testcontainers:[a-z-]+:[0-9.]+( -> [0-9.]+)?' "$OUT/testRuntimeClasspath.log" | sort -u > "$OUT/testcontainers-resolved.txt"

rcTest=$(run_logged "$W" "$OUT/presentation-test.log" ./gradlew clean :presentation:test "${GRADLE_OPTS_COMMON[@]}")
mkdir -p "$OUT/test-results"
cp "$W"/presentation/build/test-results/test/*.xml "$OUT/test-results/" 2>/dev/null || true
for x in "$OUT"/test-results/*.xml; do [ -f "$x" ] && sanitize "$W" < "$x" > "$x.s" && mv "$x.s" "$x"; done

{
  echo "rcDependencies: $rcDeps"
  echo "rcTest: $rcTest"
  echo "testsInXml: $(count_tests "$OUT/test-results")"
  echo "failuresInXml: $(sed -n 's/.*<testsuite [^>]*failures="\([0-9]*\)".*/\1/p' "$OUT"/test-results/*.xml | paste -sd+ - | bc)"
  echo "passedLinesInConsole: $(grep -c ' PASSED' "$OUT/presentation-test.log" || true)"
  echo "testsCompletedLineInConsole: $(grep -c 'tests completed' "$OUT/presentation-test.log" || true)"
  echo "hhh000478AtShutdown: $(grep -c 'HHH000478' "$OUT/presentation-test.log" || true)"
} > "$OUT/summary.txt"
rm -rf "$W"
cat "$OUT/summary.txt"; cat "$OUT/testcontainers-resolved.txt"
