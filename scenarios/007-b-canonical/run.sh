#!/usr/bin/env bash
# 007 sec03 の正典（HEAD の modulith/）で、予測 P2〜P5・P9 を確かめる
#   base      : そのまま（P2: verify の成功時に何が出るか・出力は JUnit XML の system-out で見る）
#   p2-debug  : org.springframework.modulith のログを DEBUG にして同じテストを流す（欠陥 D2 の対処）
#   p3        : ModularityTests に .withAllowedDependencies() を足す
#   p4        : notification から task.internal の型を使う（違反時の例外の型とメッセージ）
#   p4-detect : p4 の違反を detectViolations().filter(...) で除いて確かめる（段階導入の書き方）
#   p4-staged : p4-detect に加え、@ApplicationModuleTest(verifyAutomatically = false) にする（モジュール統合テストも違反で止めない）
#   p5        : テストの接続先（src/test/resources/application.properties）を消す
#   p9        : spring-modulith-starter-core を依存から外す
source "$(dirname "$0")/../lib/common.sh"
set +o pipefail
OUT="$ROOT/results/007/b-canonical"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
M=modulith; MT=$M/src/test/java/com/example/taskmaster/ModularityTests.java
NL=$M/src/main/java/com/example/taskmaster/notification/NotificationListener.java

add_violation() {
  local w="$1"
  mkdir -p "$w/$M/src/main/java/com/example/taskmaster/task/internal"
  cp "$ROOT/scenarios/007-b-canonical/fixtures/TaskValidator.java" "$w/$M/src/main/java/com/example/taskmaster/task/internal/"
  insert_after_package "$w/$NL" 'import com.example.taskmaster.task.internal.TaskValidator;'
  awk '/public class NotificationListener/ && !d { print; print ""; print "    private final TaskValidator validator = new TaskValidator();"; d=1; next } { print }' "$w/$NL" > "$w/n.new" && mv "$w/n.new" "$w/$NL"
}

variant() {
  local name="$1" W rc; W="$(new_copy)"
  case "$name" in
    base) ;;
    p2-debug) printf '%s\n' '<configuration>' '  <appender name="OUT" class="ch.qos.logback.core.ConsoleAppender"><encoder><pattern>%level %logger - %msg%n</pattern></encoder></appender>' '  <logger name="org.springframework.modulith" level="DEBUG"/>' '  <root level="INFO"><appender-ref ref="OUT"/></root>' '</configuration>' > "$W/$M/src/test/resources/logback-test.xml" ;;
    p3) sed -i.bak 's/ApplicationModules.of(TaskmasterApplication.class);/ApplicationModules.of(TaskmasterApplication.class).withAllowedDependencies();/' "$W/$MT" ;;
    p4) add_violation "$W" ;;
    p4-detect)
      add_violation "$W"
      sed -i.bak 's/        modules.verify();/        modules.detectViolations()\
                .filter(v -> !v.getMessage().contains("TaskValidator"))\
                .throwIfPresent();/' "$W/$MT" ;;
    p4-staged)
      add_violation "$W"
      sed -i.bak 's/        modules.verify();/        modules.detectViolations()\
                .filter(v -> !v.getMessage().contains("TaskValidator"))\
                .throwIfPresent();/' "$W/$MT"
      sed -i.bak 's/^@ApplicationModuleTest$/@ApplicationModuleTest(verifyAutomatically = false)/' "$W/$M/src/test/java/com/example/taskmaster/task/TaskModuleIntegrationTest.java" ;;
    p5) rm -f "$W/$M/src/test/resources/application.properties" ;;
    p9) sed -i.bak '/spring-modulith-starter-core/d' "$W/$M/build.gradle.kts" ;;
  esac
  rm -f "$W"/$M/*.bak "$W"/$M/src/*/java/com/example/taskmaster/*.bak "$W"/$M/src/*/java/com/example/taskmaster/*/*.bak 2>/dev/null
  cp "$W/$MT" "$OUT/$name-ModularityTests.java"
  rc=$(run_logged "$W" "$OUT/$name.log" ./gradlew -p modulith clean test --console=plain)
  mkdir -p "$OUT/$name-test-results"; cp "$W"/$M/build/test-results/test/*.xml "$OUT/$name-test-results/" 2>/dev/null || true
  for x in "$OUT/$name-test-results"/*.xml; do [ -f "$x" ] && sanitize "$W" < "$x" > "$x.s" && mv "$x.s" "$x"; done
  {
    echo "$name: rc=$rc tests=$(count_tests "$OUT/$name-test-results")"
    grep -h -o 'error: [^<]*' "$OUT/$name.log" | sort -u | sed 's/^/  /' | head -4
    for x in "$OUT/$name-test-results"/*.xml; do [ -f "$x" ] || continue
      sed -n 's/.*<testsuite name="\([^"]*\)" tests="\([0-9]*\)" skipped="[0-9]*" failures="\([0-9]*\)" errors="\([0-9]*\)".*/  \1 tests=\2 failures=\3 errors=\4/p' "$x"
      grep -o '<failure message="[^"]*" type="[^"]*"' "$x" | head -1 | cut -c1-400 | sed 's/^/    /'
      grep -o '<error message="[^"]*" type="[^"]*"' "$x" | head -1 | cut -c1-400 | sed 's/^/    /'
    done
    echo "  verifyingModules=$(grep -c 'Verifying modules' "$OUT"/$name-test-results/*.xml 2>/dev/null | awk -F: '{s+=$2} END{print s+0}') hasNoDependencies=$(grep -c 'has no dependencies' "$OUT"/$name-test-results/*.xml 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')"
    echo "  modulithLogLines=$(grep -h -c 'org.springframework.modulith' "$OUT"/$name-test-results/TEST-com.example.taskmaster.ModularityTests.xml 2>/dev/null || echo 0)"
  } >> "$OUT/summary.txt"
  rm -rf "$W"
}
for v in base p2-debug p3 p4 p4-detect p4-staged p5 p9; do variant "$v"; done
cat "$OUT/summary.txt"
