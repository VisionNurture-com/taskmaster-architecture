#!/usr/bin/env bash
# P6: 005 掲載の archunit-junit5-engine:1.4.1 は、JUnit Platform 6（Spring Boot 4.1.1 の管理）の上でテストを見つけるか
#   A: 掲載どおり archunit-junit5-engine:1.4.1
#   B: archunit-junit5-engine:1.5.1
#   C: archunit-junit6:1.5.1
#   Cv: C に P4 と同じ違反を入れた陰性対照（ルールが本当に判定しているか・0 件で SUCCESS を読まないため）
REF="${REF:-article-005-as-published}"
source "$(dirname "$0")/../lib/common.sh"
OUT="$ROOT/results/005/p6-archunit-junit6"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
FIX="$ROOT/scenarios/005-p6-archunit-junit6/fixtures/ProbeArchitectureTest.java"
TESTDIR=presentation/src/test/java/com/example/taskmaster/presentation
CTRL=presentation/src/main/java/com/example/taskmaster/presentation/TaskController.java
LINE='testImplementation("com.tngtech.archunit:archunit-junit5-engine:1.4.1")'

variant() {
  local name="$1" dep="$2" violate="$3" W rc
  W="$(new_copy)"
  cp "$FIX" "$W/$TESTDIR/"
  if [ "$dep" != "$LINE" ]; then
    awk -v old="$LINE" -v new="$dep" '{ if (index($0, old)) { sub(/testImplementation\(.*\)/, new) } print }' "$W/presentation/build.gradle.kts" > "$W/p.new" && mv "$W/p.new" "$W/presentation/build.gradle.kts"
  fi
  if [ "$violate" = yes ]; then
    insert_after_package "$W/$CTRL" 'import com.example.taskmaster.infrastructure.JpaTaskRepository;'
    awk '/private final TaskService taskService;/ && !d { print; print "    private JpaTaskRepository shortcut;"; d=1; next } { print }' "$W/$CTRL" > "$W/c.new" && mv "$W/c.new" "$W/$CTRL"
  fi
  grep -n 'archunit' "$W/presentation/build.gradle.kts" > "$OUT/$name-archunit-line.txt"
  rc=$(run_logged "$W" "$OUT/$name.log" ./gradlew clean :presentation:test "${GRADLE_OPTS_COMMON[@]}")
  mkdir -p "$OUT/$name-test-results"
  cp "$W"/presentation/build/test-results/test/*.xml "$OUT/$name-test-results/" 2>/dev/null || true
  for x in "$OUT/$name-test-results"/*.xml; do [ -f "$x" ] && sanitize "$W" < "$x" > "$x.s" && mv "$x.s" "$x"; done
  local probe="$OUT/$name-test-results/TEST-com.example.taskmaster.presentation.ProbeArchitectureTest.xml" pt=absent pf=absent
  if [ -f "$probe" ]; then
    pt=$(sed -n 's/.*<testsuite [^>]*tests="\([0-9]*\)".*/\1/p' "$probe" | head -1)
    pf=$(sed -n 's/.*<testsuite [^>]*failures="\([0-9]*\)".*/\1/p' "$probe" | head -1)
  fi
  echo "$name: rc=$rc testsAll=$(count_tests "$OUT/$name-test-results") probeTests=$pt probeFailures=$pf" >> "$OUT/summary.txt"
  rm -rf "$W"
}

variant A 'testImplementation("com.tngtech.archunit:archunit-junit5-engine:1.4.1")' no
variant B 'testImplementation("com.tngtech.archunit:archunit-junit5-engine:1.5.1")' no
variant C 'testImplementation("com.tngtech.archunit:archunit-junit6:1.5.1")' no
variant Cv 'testImplementation("com.tngtech.archunit:archunit-junit6:1.5.1")' yes
cat "$OUT/summary.txt"
