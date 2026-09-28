#!/usr/bin/env bash
# M5: application が domain を api / implementation のどちらで宣言するかで、
#     presentation のコードが実際にコンパイルできるかを見る。
#     presentation には次のどちらか 1 つのクラスを置く。
#       direct = domain の Task を直接使う
#       dto    = application の TaskResponse だけを使う
#     implementation については、TaskResponse の status を String にした場合も測る。
REF="${REF:-article-004}"
source "$(dirname "$0")/../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/results/004/m5-presentation-visibility"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
json="{"
for mode in api implementation implementation-string; do
  for probe in direct dto; do
    W="$(new_copy)"
    printf 'dependencies {\n    implementation(project(":application"))\n}\n' > "$W/presentation/build.gradle.kts"
    P="$W/presentation/src/main/java/com/example/taskmaster/presentation"; mkdir -p "$P"
    if [ "$probe" = direct ]; then cp "$HERE/fixtures/TaskViewDirect.java" "$P/TaskView.java"; else cp "$HERE/fixtures/TaskViewDto.java" "$P/TaskView.java"; fi
    if [ "$mode" != api ]; then
      sed 's#api(project(":domain"))#implementation(project(":domain"))#' "$W/application/build.gradle.kts" > "$W/decl.new"
      mv "$W/decl.new" "$W/application/build.gradle.kts"
    fi
    if [ "$mode" = implementation-string ]; then
      R="$W/application/src/main/java/com/example/taskmaster/application/TaskResponse.java"
      sed -e '/import com.example.taskmaster.domain.TaskStatus;/d' \
          -e 's/        TaskStatus status/        String status/' \
          -e 's/                task.getStatus()/                task.getStatus().name()/' "$R" > "$R.new"
      mv "$R.new" "$R"
      cp "$R" "$OUT/implementation-string-TaskResponse.java"
    fi
    grep -n 'project(":domain")' "$W/application/build.gradle.kts" > "$OUT/$mode-application-decl.txt"
    rc=$(run_logged "$W" "$OUT/$mode-$probe.log" ./gradlew :presentation:compileJava "${GRADLE_OPTS_COMMON[@]}")
    json="$json\"${mode}_${probe}_rc\": $rc, "
    rm -rf "$W"
  done
done
printf '%s}\n' "${json%, }" > "$OUT/summary.json"
cat "$OUT/summary.json"
