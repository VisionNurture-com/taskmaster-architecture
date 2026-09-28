#!/usr/bin/env bash
# 005 sec04 の表の各行が「コンパイルで止まるか」を確かめる（ArchUnit のルールは使わない）
#   P3-0: domain に Spring の import だけを入れる（依存は足さない）  → 表 3 行目
#   P3  : domain の build.gradle.kts に spring-context を足してから import と @Component → 表 5 行目
#   P4  : TaskController から JpaTaskRepository を import               → 表 4 行目・✏️ やってみよう
#   P8a : presentation の infrastructure 依存を runtimeOnly にして P4 と同じ import
#   P8b : runtimeOnly のまま import なしで統合テスト（Spring が JpaTaskRepository を見つけるか）と bootJar の中身
REF="${REF:-article-005-as-published}"
source "$(dirname "$0")/../lib/common.sh"
OUT="$ROOT/results/005/p3-p4-p8-compile-boundaries"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
TASK=domain/src/main/java/com/example/taskmaster/domain/Task.java
CTRL=presentation/src/main/java/com/example/taskmaster/presentation/TaskController.java
SPRING_IMPORT='import org.springframework.stereotype.Component;'
INFRA_IMPORT='import com.example.taskmaster.infrastructure.JpaTaskRepository;'
annotate_task() { awk '/^public class Task / && !d { print "@Component"; d=1 } { print }' "$1" > "$1.new" && mv "$1.new" "$1"; }
use_infra_in_ctrl() { awk '/private final TaskService taskService;/ && !d { print; print "    private JpaTaskRepository shortcut;"; d=1; next } { print }' "$1" > "$1.new" && mv "$1.new" "$1"; }
to_runtime_only() { sed 's#implementation(project(":infrastructure"))#runtimeOnly(project(":infrastructure"))#' "$1" > "$1.new" && mv "$1.new" "$1"; }

W="$(new_copy)"; insert_after_package "$W/$TASK" "$SPRING_IMPORT"
rcP30=$(run_logged "$W" "$OUT/P3-0-import-only.log" ./gradlew :domain:compileJava "${GRADLE_OPTS_COMMON[@]}"); rm -rf "$W"

W="$(new_copy)"; printf '\ndependencies {\n    implementation("org.springframework:spring-context")\n}\n' >> "$W/domain/build.gradle.kts"
insert_after_package "$W/$TASK" "$SPRING_IMPORT"; annotate_task "$W/$TASK"
head -8 "$W/$TASK" > "$OUT/P3-task-head.txt"; cp "$W/domain/build.gradle.kts" "$OUT/P3-domain-build.gradle.kts"
rcP3=$(run_logged "$W" "$OUT/P3-dependency-then-import.log" ./gradlew :domain:compileJava "${GRADLE_OPTS_COMMON[@]}"); rm -rf "$W"

W="$(new_copy)"; insert_after_package "$W/$CTRL" "$INFRA_IMPORT"; use_infra_in_ctrl "$W/$CTRL"
rcP4=$(run_logged "$W" "$OUT/P4-controller-imports-infra.log" ./gradlew :presentation:compileJava "${GRADLE_OPTS_COMMON[@]}"); rm -rf "$W"

W="$(new_copy)"; to_runtime_only "$W/presentation/build.gradle.kts"; insert_after_package "$W/$CTRL" "$INFRA_IMPORT"; use_infra_in_ctrl "$W/$CTRL"
cp "$W/presentation/build.gradle.kts" "$OUT/P8-presentation-build.gradle.kts"
rcP8a=$(run_logged "$W" "$OUT/P8a-runtimeOnly-import.log" ./gradlew :presentation:compileJava "${GRADLE_OPTS_COMMON[@]}"); rm -rf "$W"

W="$(new_copy)"; to_runtime_only "$W/presentation/build.gradle.kts"
rcP8b=$(run_logged "$W" "$OUT/P8b-runtimeOnly-test.log" ./gradlew clean :presentation:test :presentation:bootJar "${GRADLE_OPTS_COMMON[@]}")
mkdir -p "$OUT/P8b-test-results"; cp "$W"/presentation/build/test-results/test/*.xml "$OUT/P8b-test-results/" 2>/dev/null || true
for x in "$OUT"/P8b-test-results/*.xml; do [ -f "$x" ] && sanitize "$W" < "$x" > "$x.s" && mv "$x.s" "$x"; done
jar="$(ls "$W"/presentation/build/libs/*.jar 2>/dev/null | grep -v plain | head -1)"
if [ -n "$jar" ]; then unzip -l "$jar" | grep -oE 'BOOT-INF/lib/(domain|application|infrastructure)[^ ]*' | sort > "$OUT/P8b-bootjar-project-libs.txt"; fi
rm -rf "$W"

{
  echo "rcP3_0_importOnly: $rcP30"
  echo "rcP3_dependencyThenImport: $rcP3"
  echo "rcP4_controllerImportsInfra: $rcP4"
  echo "rcP8a_runtimeOnlyImport: $rcP8a"
  echo "rcP8b_runtimeOnlyTestAndBootJar: $rcP8b"
  echo "P8b_testsInXml: $(count_tests "$OUT/P8b-test-results")"
  echo "P8b_bootJarProjectLibs: $(paste -sd, "$OUT/P8b-bootjar-project-libs.txt" 2>/dev/null)"
} > "$OUT/summary.txt"
cat "$OUT/summary.txt"
