#!/usr/bin/env bash
# 測定シナリオの共通関数。HEAD を使い捨ての一時ディレクトリへ展開して、その中で測る。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GRADLE_OPTS_COMMON=(--console=plain --no-build-cache --no-configuration-cache)

# HEAD のコピーを作り、そのパスを返す（作業ツリーの未コミット変更は含めない）
new_copy() {
  local d
  d="$(mktemp -d)"
  git -C "$ROOT" archive HEAD | tar -x -C "$d"
  echo "$d"
}

# 出力から一時ディレクトリとホームのパスを除く
sanitize() {
  local work="$1"
  sed -e "s#${work}#<work>#g" -e "s#${HOME}#~#g" -e 's#/private<work>#<work>#g'
}

# コマンドを実行し、終了コードと出力をログへ残す（set -e で止めない）
run_logged() {
  local work="$1" log="$2"; shift 2
  local rc=0
  ( cd "$work" && "$@" ) > "$log.raw" 2>&1 || rc=$?
  sanitize "$work" < "$log.raw" > "$log"
  rm -f "$log.raw"
  echo "$rc"
}

# 実行環境の版を記録する
record_env() {
  local out="$1"
  {
    echo "measuredAt: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "gitHead: $(git -C "$ROOT" rev-parse --short HEAD)"
    echo "os: $(uname -s) $(uname -r) $(uname -m)"
    echo "java: $(java -version 2>&1 | head -1)"
    echo "gradleWrapper: $(grep distributionUrl "$ROOT/gradle/wrapper/gradle-wrapper.properties" | sed 's#.*gradle-##; s#-bin.zip##')"
    echo "loadAverage: $(uptime | sed 's/.*load averages*: //')"
  } > "$out"
}

# package 宣言の直後に 1 行を挿入する（BSD / GNU sed の差を避けて awk で行う）
insert_after_package() {
  local file="$1" line="$2"
  awk -v l="$line" '{ print } /^package / && !done { print l; done=1 }' "$file" > "$file.new" && mv "$file.new" "$file"
}

# JUnit XML の tests 属性を合計する
count_tests() {
  local dir="$1" n=0 x t
  for x in "$dir"/*.xml; do
    [ -f "$x" ] || continue
    t=$(sed -n 's/.*<testsuite [^>]*tests="\([0-9]*\)".*/\1/p' "$x" | head -1)
    n=$(( n + ${t:-0} ))
  done
  echo "$n"
}
