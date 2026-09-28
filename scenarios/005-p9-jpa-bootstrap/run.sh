#!/usr/bin/env bash
# P9: spring.jpa.bootstrap=async は何も足さずに起動できるか・起動時間は default と比べてどうか
#   bootJar を 1 回作り、PostgreSQL のコンテナを 1 つ立て、default / async を交互に N 回ずつ起動する
source "$(dirname "$0")/../lib/common.sh"
OUT="$ROOT/results/005/p9-jpa-bootstrap"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
N="${N:-5}"; MAX_WAIT=90
W="$(new_copy)"
rcJar=$(run_logged "$W" "$OUT/bootJar.log" ./gradlew :presentation:bootJar "${GRADLE_OPTS_COMMON[@]}")
JAR="$(ls "$W"/presentation/build/libs/*.jar | grep -v plain | head -1)"
CID="$(docker run -d --rm -e POSTGRES_DB=taskmaster -e POSTGRES_USER=taskmaster -e POSTGRES_PASSWORD=taskmaster -p 127.0.0.1::5432 postgres:17-alpine)"
trap 'docker rm -f "$CID" >/dev/null 2>&1 || true; rm -rf "$W"' EXIT
PORT="$(docker port "$CID" 5432/tcp | head -1 | sed 's/.*://')"
for i in $(seq 1 30); do docker exec "$CID" pg_isready -U taskmaster >/dev/null 2>&1 && break; sleep 1; done
echo "postgresImage: postgres:17-alpine" >> "$OUT/env.txt"

run_once() {
  local mode="$1" i="$2"
  local log="$OUT/run-$mode-$i.log" pid waited=0
  java -jar "$JAR" --spring.docker.compose.enabled=false \
    --spring.datasource.url="jdbc:postgresql://127.0.0.1:$PORT/taskmaster" \
    --spring.datasource.username=taskmaster --spring.datasource.password=taskmaster \
    --spring.jpa.bootstrap="$mode" --spring.jpa.show-sql=false --server.port=0 > "$log.raw" 2>&1 &
  pid=$!
  while [ $waited -lt $MAX_WAIT ]; do
    grep -q 'Started TaskmasterApplication in' "$log.raw" && break
    kill -0 "$pid" 2>/dev/null || break
    sleep 1; waited=$((waited + 1))
  done
  kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
  sanitize "$W" < "$log.raw" > "$log"; rm -f "$log.raw"
  local s; s=$(grep -oE 'Started TaskmasterApplication in [0-9.]+ seconds' "$log" | grep -oE '[0-9.]+' | head -1)
  echo "$mode $i ${s:-FAILED}" >> "$OUT/startup-seconds.txt"
}

for i in $(seq 1 "$N"); do run_once default "$i"; run_once async "$i"; done
{
  echo "rcBootJar: $rcJar"
  echo "runsPerMode: $N"
  for m in default async; do
    vals=$(awk -v m=$m '$1==m{print $3}' "$OUT/startup-seconds.txt" | tr '\n' ' ')
    echo "$m: $vals"
    echo "$m median: $(awk -v m=$m '$1==m && $3!="FAILED"{print $3}' "$OUT/startup-seconds.txt" | sort -n | awk '{a[NR]=$1} END{ if(NR==0){print "n/a"} else if(NR%2){print a[(NR+1)/2]} else {print (a[NR/2]+a[NR/2+1])/2} }')"
  done
  echo "asyncBootstrapExecutorLine: $(grep -h -m1 -iE 'bootstrap|applicationTaskExecutor' "$OUT"/run-async-1.log | head -1 | cut -c1-200)"
} > "$OUT/summary.txt"
cat "$OUT/summary.txt"
