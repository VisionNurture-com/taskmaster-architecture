#!/usr/bin/env bash
# M1: domain に Spring の import を 1 行入れたとき、どこで止まるか
#   A = パッケージ分割（1 つのプロジェクトに domain / application を同居・spring-context を依存に持つ）
#   B = プロジェクト分割（本リポジトリの構成のまま）
REF="${REF:-article-004}"
source "$(dirname "$0")/../lib/common.sh"
OUT="$ROOT/results/004/m1-violation"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
VIOLATION='import org.springframework.stereotype.Component;'
TASK=src/main/java/com/example/taskmaster/domain/Task.java

# --- A: パッケージ分割 ---
W="$(new_copy)"
mkdir -p "$W/single/src/main/java"
cp -R "$W/domain/src/main/java/." "$W/single/src/main/java/"
cp -R "$W/application/src/main/java/." "$W/single/src/main/java/"
cat > "$W/single/settings.gradle.kts" <<'KTS'
rootProject.name = "single"
KTS
cat > "$W/single/build.gradle.kts" <<'KTS'
plugins {
    java
    id("io.spring.dependency-management") version "1.1.7"
}
repositories { mavenCentral() }
dependencyManagement {
    imports { mavenBom("org.springframework.boot:spring-boot-dependencies:4.1.1") }
}
java { toolchain { languageVersion = JavaLanguageVersion.of(25) } }
dependencies {
    implementation("org.springframework:spring-context")
    implementation("org.springframework:spring-tx")
}
KTS
insert_after_package "$W/single/$TASK" "$VIOLATION"
head -3 "$W/single/$TASK" > "$OUT/A-task-head.txt"
rcA=$(run_logged "$W" "$OUT/A-package-split.log" ./gradlew -p single compileJava "${GRADLE_OPTS_COMMON[@]}")
rm -rf "$W"

# --- B: プロジェクト分割 ---
W="$(new_copy)"
insert_after_package "$W/domain/$TASK" "$VIOLATION"
head -3 "$W/domain/$TASK" > "$OUT/B-task-head.txt"
rcB=$(run_logged "$W" "$OUT/B-project-split.log" ./gradlew :domain:compileJava "${GRADLE_OPTS_COMMON[@]}")
rm -rf "$W"

printf '{"A_packageSplit_rc": %s, "B_projectSplit_rc": %s}\n' "$rcA" "$rcB" > "$OUT/summary.json"
cat "$OUT/summary.json"
