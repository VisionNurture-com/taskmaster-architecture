#!/usr/bin/env bash
# M2: application が domain を api で宣言するか implementation で宣言するかで、
#     presentation のコンパイル時クラスパスに domain が現れるかを依存レポートで見る
REF="${REF:-article-004}"
source "$(dirname "$0")/../lib/common.sh"
OUT="$ROOT/results/004/m2-api-vs-implementation"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
json="{"
for mode in api implementation; do
  W="$(new_copy)"
  printf 'dependencies {\n    implementation(project(":application"))\n}\n' > "$W/presentation/build.gradle.kts"
  cp "$W/presentation/build.gradle.kts" "$OUT/presentation-build.gradle.kts"
  if [ "$mode" = implementation ]; then
    sed 's#api(project(":domain"))#implementation(project(":domain"))#' "$W/application/build.gradle.kts" > "$W/application/build.gradle.kts.new"
    mv "$W/application/build.gradle.kts.new" "$W/application/build.gradle.kts"
  fi
  grep -n 'project(":domain")' "$W/application/build.gradle.kts" > "$OUT/$mode-application-decl.txt"
  for cfg in compileClasspath runtimeClasspath; do
    run_logged "$W" "$OUT/$mode-presentation-$cfg.log" ./gradlew -q :presentation:dependencies --configuration "$cfg" "${GRADLE_OPTS_COMMON[@]}" > /dev/null
    if grep -q "project ':domain'" "$OUT/$mode-presentation-$cfg.log"; then has=true; else has=false; fi
    json="$json\"${mode}_${cfg}_hasDomain\": $has, "
  done
  rm -rf "$W"
done
printf '%s}\n' "${json%, }" > "$OUT/summary.json"
cat "$OUT/summary.json"
