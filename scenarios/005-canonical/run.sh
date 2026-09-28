#!/usr/bin/env bash
# 005 の正典（HEAD）で、記事の R6 に載せる出力を取る
#   test   : ./gradlew :presentation:test（統合テスト・ERROR / WARN 行の有無）
#   import : TaskController から JpaTaskRepository を import したときの compileJava（✏️ やってみよう）
source "$(dirname "$0")/../lib/common.sh"
set +o pipefail
OUT="$ROOT/results/005/canonical"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
CTRL=presentation/src/main/java/com/example/taskmaster/presentation/TaskController.java

W="$(new_copy)"
rcTest=$(run_logged "$W" "$OUT/presentation-test.log" ./gradlew :presentation:test --console=plain)
mkdir -p "$OUT/test-results"; cp "$W"/presentation/build/test-results/test/*.xml "$OUT/test-results/" 2>/dev/null || true
for x in "$OUT"/test-results/*.xml; do [ -f "$x" ] && sanitize "$W" < "$x" > "$x.s" && mv "$x.s" "$x"; done
rm -rf "$W"

W="$(new_copy)"
insert_after_package "$W/$CTRL" 'import com.example.taskmaster.infrastructure.JpaTaskRepository;'
rcImport=$(run_logged "$W" "$OUT/compile-with-infra-import.log" ./gradlew :presentation:compileJava --console=plain)
rm -rf "$W"

{
  echo "rcTest: $rcTest"
  echo "testsInXml: $(count_tests "$OUT/test-results")"
  echo "errorLines: $(grep -c ' ERROR ' "$OUT/presentation-test.log" || true)"
  echo "warnLines: $(grep -c ' WARN ' "$OUT/presentation-test.log" || true)"
  echo "rcCompileWithInfraImport: $rcImport"
  echo "importError: $(grep -m1 'error:' "$OUT/compile-with-infra-import.log" | sed 's#.*/presentation/#presentation/#')"
} > "$OUT/summary.txt"
cat "$OUT/summary.txt"
