#!/usr/bin/env bash
# 002 の手順を記事の順に動かす（タグ article-002・Spring Boot 4.1.1）
#   test    : ./gradlew test
#   bootrun : ./gradlew bootRun（compose.yml）→ 記事の curl を記事の順に（PUT の直後に GET を 1 本足す: Q6）
#   q5      : spring-boot-starter-webmvc を旧名の spring-boot-starter-web に替えて ./gradlew test
REF="${REF:-article-002}"
source "$(dirname "$0")/../lib/common.sh"
set +o pipefail
OUT="$ROOT/results/002/canonical"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"; echo "jq: $(jq --version)" >> "$OUT/env.txt"

W="$(new_copy)"
rcTest=$(run_logged "$W" "$OUT/test.log" ./gradlew test --console=plain)
mkdir -p "$OUT/test-results"; cp "$W"/build/test-results/test/*.xml "$OUT/test-results/" 2>/dev/null || true
for x in "$OUT"/test-results/*.xml; do [ -f "$x" ] && sanitize "$W" < "$x" > "$x.s" && mv "$x.s" "$x"; done
rm -rf "$W"

W="$(new_copy)"
sed -i.bak 's#spring-boot-starter-webmvc"#spring-boot-starter-web"#' "$W/build.gradle.kts"; rm -f "$W/build.gradle.kts.bak"
grep -n 'starter-web' "$W/build.gradle.kts" > "$OUT/q5-starter-line.txt"
rcQ5=$(run_logged "$W" "$OUT/q5-starter-web.log" ./gradlew test --console=plain)
rm -rf "$W"

MAX_WAIT=180
W="$(new_copy)"
stop_app() { local app; app="$(lsof -ti tcp:8080 -sTCP:LISTEN 2>/dev/null || true)"; [ -n "$app" ] && kill $app 2>/dev/null || true; }
cleanup() { stop_app; [ -n "${GPID:-}" ] && kill "$GPID" 2>/dev/null || true; sleep 3; ( cd "$W" && docker compose down -v >/dev/null 2>&1 ) || true; rm -rf "$W"; }
trap cleanup EXIT
( cd "$W" && ./gradlew bootRun --console=plain > "$OUT/bootRun.log.raw" 2>&1 ) &
GPID=$!
waited=0
while [ $waited -lt $MAX_WAIT ]; do
  grep -q 'Started TaskmasterApplication in' "$OUT/bootRun.log.raw" && break
  kill -0 "$GPID" 2>/dev/null || break
  sleep 1; waited=$((waited + 1))
done
started=$(grep -c 'Started TaskmasterApplication in' "$OUT/bootRun.log.raw" || true)
if [ "$started" -ge 1 ]; then
  curl -s -X POST http://localhost:8080/api/tasks \
    -H "Content-Type: application/json" \
    -d '{"title":"Spring Boot 4を学ぶ","description":"3層アーキテクチャのハンズオン"}' | jq > "$OUT/curl-1-post.txt" 2>&1
  curl -s http://localhost:8080/api/tasks | jq > "$OUT/curl-2-list.txt" 2>&1
  curl -s -X PUT http://localhost:8080/api/tasks/1 \
    -H "Content-Type: application/json" \
    -d '{"title":"Spring Boot 4を学ぶ（更新）","description":"CRUD完成！"}' | jq > "$OUT/curl-3-put.txt" 2>&1
  curl -s http://localhost:8080/api/tasks/1 | jq > "$OUT/curl-3b-get-after-put.txt" 2>&1
  curl -s -X DELETE http://localhost:8080/api/tasks/1 -w "\nHTTP Status: %{http_code}\n" > "$OUT/curl-4-delete.txt" 2>&1
  curl -s -X POST http://localhost:8080/api/tasks \
    -H "Content-Type: application/json" \
    -d '{"title":"","description":"テスト"}' | jq > "$OUT/curl-5-validation.txt" 2>&1
fi
stop_app; sleep 5
sanitize "$W" < "$OUT/bootRun.log.raw" | sed -E 's#/private/var/folders/[^ ]*/T/tmp\.[A-Za-z0-9]+#<work>#g; s#/var/folders/[^ ]*/T/tmp\.[A-Za-z0-9]+#<work>#g' > "$OUT/bootRun.log"; rm -f "$OUT/bootRun.log.raw"
{
  echo "rcTest: $rcTest"
  echo "testsInXml: $(count_tests "$OUT/test-results")"
  echo "rcQ5_starterWeb: $rcQ5"
  echo "q5DeprecationLines: $(grep -ci 'deprecat' "$OUT/q5-starter-web.log" || true)"
  echo "bootRunStarted: $started (waited ${waited}s)"
  echo "postHasFraction: $(grep -cE '"createdAt": "[0-9T:-]+\.[0-9]+' "$OUT/curl-1-post.txt" 2>/dev/null || echo 0)"
  echo "validationHasType: $(grep -c '"type"' "$OUT/curl-5-validation.txt" 2>/dev/null || echo 0)"
  echo "validationHasInstance: $(grep -c '"instance"' "$OUT/curl-5-validation.txt" 2>/dev/null || echo 0)"
  echo "putResponseUpdatedEqualsCreated: $(python3 -c "import json;d=json.load(open('$OUT/curl-3-put.txt'));print(d['updatedAt']==d['createdAt'])" 2>/dev/null)"
  echo "getAfterPutUpdatedAfterCreated: $(python3 -c "import json;d=json.load(open('$OUT/curl-3b-get-after-put.txt'));print(d['updatedAt']>d['createdAt'])" 2>/dev/null)"
} > "$OUT/summary.txt"
cat "$OUT/summary.txt"
