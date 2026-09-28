#!/usr/bin/env bash
# 005 sec05 の「動作確認」を記事の順に実行し、実行結果をそのまま残す（R2: 手で整えない）
#   ./gradlew :presentation:bootRun（Docker Compose 連携で PostgreSQL を起動）→ curl 3 本
#   VARIANT=as-written            : 記事どおり（compose.yaml はプロジェクトルート）
#   VARIANT=compose-file-property : application.yml に spring.docker.compose.file: ../compose.yaml を足す
#   VARIANT=bootrun-workingdir    : presentation/build.gradle.kts で bootRun の作業ディレクトリをルートにする
#   VARIANT=compose-in-presentation : compose.yaml を presentation/ へ移す
#   VARIANT=canonical             : HEAD（bootRun の作業ディレクトリをルートにした版）をそのまま動かす。ほかの 4 つは掲載どおりのタグを土台にする
VARIANT="${VARIANT:-as-written}"
[ "$VARIANT" = canonical ] || REF="${REF:-article-005-as-published}"
source "$(dirname "$0")/../lib/common.sh"
set +o pipefail
OUT="$ROOT/results/005/sec05-bootrun-curl/$VARIANT"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
echo "variant: $VARIANT" >> "$OUT/env.txt"
echo "jq: $(jq --version)" >> "$OUT/env.txt"; echo "curl: $(curl --version | head -1 | cut -d' ' -f1-2)" >> "$OUT/env.txt"
MAX_WAIT=180
W="$(new_copy)"
case "$VARIANT" in
  as-written|canonical) ;;
  compose-file-property)
    printf '  docker:\n    compose:\n      file: ../compose.yaml\n' > "$W/tmp.yml"
    awk 'NR==1 && /^spring:/ { print; while ((getline l < "'"$W/tmp.yml"'") > 0) print l; next } { print }' "$W/presentation/src/main/resources/application.yml" > "$W/a.new" && mv "$W/a.new" "$W/presentation/src/main/resources/application.yml"; rm -f "$W/tmp.yml"
    cp "$W/presentation/src/main/resources/application.yml" "$OUT/application.yml" ;;
  bootrun-workingdir)
    printf '\ntasks.named<org.springframework.boot.gradle.tasks.run.BootRun>("bootRun") {\n    workingDir = rootProject.projectDir\n}\n' >> "$W/presentation/build.gradle.kts"
    cp "$W/presentation/build.gradle.kts" "$OUT/presentation-build.gradle.kts" ;;
  compose-in-presentation) mv "$W/compose.yaml" "$W/presentation/compose.yaml" ;;
  *) echo "unknown VARIANT" >&2; exit 3 ;;
esac

stop_app() { local app; app="$(lsof -ti tcp:8080 -sTCP:LISTEN 2>/dev/null || true)"; [ -n "$app" ] && kill $app 2>/dev/null || true; }
cleanup() {
  stop_app
  [ -n "${GPID:-}" ] && kill "$GPID" 2>/dev/null || true
  sleep 3
  ( cd "$W" && docker compose -f "$(ls "$W"/compose.yaml "$W"/presentation/compose.yaml 2>/dev/null | head -1)" down -v >/dev/null 2>&1 ) || true
  rm -rf "$W"
}
trap cleanup EXIT

( cd "$W" && ./gradlew :presentation:bootRun --console=plain > "$OUT/bootRun.log.raw" 2>&1 ) &
GPID=$!
waited=0
while [ $waited -lt $MAX_WAIT ]; do
  grep -q 'Started TaskmasterApplication in' "$OUT/bootRun.log.raw" && break
  kill -0 "$GPID" 2>/dev/null || break
  sleep 1; waited=$((waited + 1))
done
started=$(grep -c 'Started TaskmasterApplication in' "$OUT/bootRun.log.raw" || true)

if [ "$started" -ge 1 ]; then
  {
    echo '$ curl -s -X POST http://localhost:8080/api/tasks \'
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -d '{\"title\":\"初めてのタスク\",\"description\":\"テスト\",\"dueDate\":\"2026-06-01\"}' | jq ."
    curl -s -X POST http://localhost:8080/api/tasks \
      -H 'Content-Type: application/json' \
      -d '{"title":"初めてのタスク","description":"テスト","dueDate":"2026-06-01"}' | jq .
  } > "$OUT/curl-1-post.txt" 2>&1
  { echo '$ curl -s http://localhost:8080/api/tasks | jq .'; curl -s http://localhost:8080/api/tasks | jq .; } > "$OUT/curl-2-list.txt" 2>&1
  { echo '$ curl -s http://localhost:8080/api/tasks/999 | jq .'; curl -s http://localhost:8080/api/tasks/999 | jq .; } > "$OUT/curl-3-notfound.txt" 2>&1
  { echo '$ curl -s -i http://localhost:8080/api/tasks/999'; curl -s -i http://localhost:8080/api/tasks/999; echo; } > "$OUT/curl-3-notfound-headers.txt" 2>&1
fi
stop_app; sleep 5
sanitize "$W" < "$OUT/bootRun.log.raw" | sed -E 's#/private/var/folders/[^ ]*/T/tmp\.[A-Za-z0-9]+#<work>#g; s#/var/folders/[^ ]*/T/tmp\.[A-Za-z0-9]+#<work>#g' > "$OUT/bootRun.log"; rm -f "$OUT/bootRun.log.raw"
{
  echo "waitedSeconds: $waited"
  echo "started: $started"
  echo "noComposeFile: $(grep -c 'No Docker Compose file found' "$OUT/bootRun.log" || true)"
  echo "postHasId: $(grep -c '"id"' "$OUT/curl-1-post.txt" 2>/dev/null || echo 0)"
  echo "notFoundHasType: $(grep -c '"type"' "$OUT/curl-3-notfound.txt" 2>/dev/null || echo 0)"
} > "$OUT/summary.txt"
cat "$OUT/summary.txt"
