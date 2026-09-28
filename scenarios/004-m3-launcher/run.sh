#!/usr/bin/env bash
# M3: domain のテストが起動するかを 4 通りで見る
#   a = ランチャーなし・Spring Boot プラグインなし
#   b = ランチャーなし・domain に org.springframework.boot を適用
#   c = ランチャーなし・JUnit Jupiter の宣言もなし・JVM Test Suites（useJUnitJupiter()）
#   d = ランチャーあり（本リポジトリの構成のまま）
source "$(dirname "$0")/../lib/common.sh"
OUT="$ROOT/results/004/m3-launcher"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
LAUNCHER='testRuntimeOnly("org.junit.platform:junit-platform-launcher")'
json="{"
for c in a b c d; do
  W="$(new_copy)"
  F="$W/domain/build.gradle.kts"
  case "$c" in
    a) grep -v -F "$LAUNCHER" "$F" > "$F.new"; mv "$F.new" "$F" ;;
    b) grep -v -F "$LAUNCHER" "$F" > "$F.new"
       { printf 'plugins {\n    id("org.springframework.boot")\n}\n\n'; cat "$F.new"; } > "$F"; rm "$F.new" ;;
    c) grep -v -F -e "$LAUNCHER" -e 'org.junit.jupiter:junit-jupiter' "$F" > "$F.new"; mv "$F.new" "$F"
       printf '\ntesting {\n    suites {\n        named<JvmTestSuite>("test") {\n            useJUnitJupiter()\n        }\n    }\n}\n' >> "$F" ;;
    d) : ;;
  esac
  cp "$F" "$OUT/$c-domain-build.gradle.kts"
  rc=$(run_logged "$W" "$OUT/$c-test.log" ./gradlew :domain:test "${GRADLE_OPTS_COMMON[@]}")
  run_logged "$W" "$OUT/$c-testRuntimeClasspath.log" ./gradlew -q :domain:dependencies --configuration testRuntimeClasspath "${GRADLE_OPTS_COMMON[@]}" > /dev/null
  n=$(count_tests "$W/domain/build/test-results/test")
  json="$json\"${c}_rc\": $rc, \"${c}_tests\": $n, "
  rm -rf "$W"
done
printf '%s}\n' "${json%, }" > "$OUT/summary.json"
cat "$OUT/summary.json"
