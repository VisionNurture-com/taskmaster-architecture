#!/usr/bin/env bash
# 007 sec03 の掲載どおりの状態（タグ article-007-as-published）を段階ごとに測る
#   stage0: そのまま（P6: TaskService のブロック / P1: assertThat の import）
#   stage1: TaskService のブロックを 2 ファイルに分け import を補う（記事の意図どおりの最小の直し）
#   stage2: stage1 + TaskModuleIntegrationTest に assertThat の import を補う（P7 / P8 / P2）
REF="${REF:-article-007-as-published}"
source "$(dirname "$0")/../lib/common.sh"
set +o pipefail
OUT="$ROOT/results/007/a-as-published"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
TS=modulith/src/main/java/com/example/taskmaster/task
IT=modulith/src/test/java/com/example/taskmaster/task/TaskModuleIntegrationTest.java

split_task_service() {
  local w="$1"
  cat > "$w/$TS/TaskCompletedEvent.java" <<'JAVA'
package com.example.taskmaster.task;

public record TaskCompletedEvent(Long taskId, String title) {}
JAVA
  awk '/^public record TaskCompletedEvent/ { next } { print }' "$w/$TS/TaskService.java" > "$w/t.new"
  awk '/^package / && !d { print; print ""; print "import org.springframework.context.ApplicationEventPublisher;"; print "import org.springframework.stereotype.Service;"; print "import org.springframework.transaction.annotation.Transactional;"; d=1; next } { print }' "$w/t.new" > "$w/$TS/TaskService.java"; rm -f "$w/t.new"
}

stage() {
  local name="$1" W rc; W="$(new_copy)"
  [ "$name" = stage0 ] || split_task_service "$W"
  [ "$name" = stage2 ] && insert_after_package "$W/$IT" 'import static org.assertj.core.api.Assertions.assertThat;'
  rc=$(run_logged "$W" "$OUT/$name.log" ./gradlew -p modulith clean test --console=plain)
  mkdir -p "$OUT/$name-test-results"; cp "$W"/modulith/build/test-results/test/*.xml "$OUT/$name-test-results/" 2>/dev/null || true
  for x in "$OUT/$name-test-results"/*.xml; do [ -f "$x" ] && sanitize "$W" < "$x" > "$x.s" && mv "$x.s" "$x"; done
  {
    echo "$name: rc=$rc tests=$(count_tests "$OUT/$name-test-results")"
    echo "  compileErrors=$(grep -c 'error:' "$OUT/$name.log" || true)"
    grep -h -o 'error: [^<]*' "$OUT/$name.log" | sort | uniq -c | sed 's/^/    /' | head -8
    for x in "$OUT/$name-test-results"/*.xml; do [ -f "$x" ] || continue; sed -n 's/.*<testsuite name="\([^"]*\)" tests="\([0-9]*\)" skipped="[0-9]*" failures="\([0-9]*\)" errors="\([0-9]*\)".*/    \1 tests=\2 failures=\3 errors=\4/p' "$x"; grep -o 'message="[^"]*"' "$x" | head -2 | cut -c1-220 | sed 's/^/      /'; done
    echo "  verifyingModulesLines=$(grep -c 'Verifying modules' "$OUT/$name.log" || true) hasNoDependenciesLines=$(grep -c 'has no dependencies' "$OUT/$name.log" || true)"
  } >> "$OUT/summary.txt"
  rm -rf "$W"
}
stage stage0; stage stage1; stage stage2
cat "$OUT/summary.txt"
