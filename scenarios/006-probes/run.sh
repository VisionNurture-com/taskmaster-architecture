#!/usr/bin/env bash
# 006 の主張を測る（予測 R1〜R14）。測定用のテストを一時ディレクトリにだけ置く（本体のコードは変えない）
#   canonical : HEAD（Spring Boot 4.1.1 / Hibernate 7.4.5）で infrastructure と presentation の測定用テストを流す
#   boot405   : ルートの build.gradle.kts を Spring Boot 4.0.5 にして、クエリ数の測定だけを流す（R8）
#   r10       : 記事 sec05 の「TaskService での使用例」（springDataRepo を使う）を application に置いてコンパイルする
#   r15       : JpaTaskRepository#save を「id があれば読み込んだエンティティを書き換える」形にして R14 を測り直す
#   c1        : 記事 sec01 のトランザクションスクリプトと sec02 の Before（Fat Service）を application に置いてコンパイルする
source "$(dirname "$0")/../lib/common.sh"
set +o pipefail
OUT="$ROOT/results/006/probes"; rm -rf "$OUT"; mkdir -p "$OUT"
record_env "$OUT/env.txt"
FIX="$ROOT/scenarios/006-probes/fixtures"
INFRA_TEST=infrastructure/src/test/java/com/example/taskmaster/infrastructure
PRES_TEST=presentation/src/test/java/com/example/taskmaster/presentation
SVC=application/src/main/java/com/example/taskmaster/application/TaskService.java

add_probes() {
  local w="$1"
  mkdir -p "$w/$INFRA_TEST"
  cp "$FIX"/infra/*.java "$w/$INFRA_TEST/"
  cp "$FIX"/presentation/*.java "$w/$PRES_TEST/"
  cat >> "$w/infrastructure/build.gradle.kts" <<'KTS'

// --- 測定用（記事の外）---
dependencies {
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.boot:spring-boot-testcontainers")
    testImplementation("org.testcontainers:testcontainers-junit-jupiter")
    testImplementation("org.testcontainers:testcontainers-postgresql")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
KTS
  cat >> "$w/presentation/build.gradle.kts" <<'KTS'

// --- 測定用（記事の外）---
dependencies {
    testImplementation("org.springframework:spring-tx")
}
KTS
}

collect() {
  local w="$1" name="$2"
  mkdir -p "$OUT/$name-test-results"
  cp "$w"/infrastructure/build/test-results/test/*.xml "$w"/presentation/build/test-results/test/*.xml "$OUT/$name-test-results/" 2>/dev/null || true
  for x in "$OUT/$name-test-results"/*.xml; do [ -f "$x" ] && sanitize "$w" < "$x" > "$x.s" && mv "$x.s" "$x"; done
  grep -h -o 'PROBE [A-Za-z0-9_]*=[^&<]*' "$OUT/$name-test-results"/*.xml 2>/dev/null | sed 's/^PROBE /  /' | sort -u
}

# --- canonical ---
W="$(new_copy)"; add_probes "$W"
rc=$(run_logged "$W" "$OUT/canonical.log" ./gradlew clean :infrastructure:test :presentation:test --tests '*ProbeTest' --console=plain)
{ echo "canonical: rc=$rc tests=$(count_tests "$W/infrastructure/build/test-results/test")+$(count_tests "$W/presentation/build/test-results/test")"; collect "$W" canonical; } >> "$OUT/summary.txt"
rm -rf "$W"

# --- boot405 (R8) ---
W="$(new_copy)"; add_probes "$W"
sed -i.bak 's/4\.1\.1/4.0.5/g' "$W/build.gradle.kts"; rm -f "$W/build.gradle.kts.bak"
grep -n '4\.0\.5' "$W/build.gradle.kts" > "$OUT/boot405-version-lines.txt"
rc=$(run_logged "$W" "$OUT/boot405.log" ./gradlew clean :infrastructure:test --tests '*QueryCountProbeTest' --tests '*BatchSizeProbeTest' --console=plain)
{ echo "boot405: rc=$rc hibernate=$(grep -h -o 'Hibernate ORM core version [0-9A-Za-z.]*' "$W"/infrastructure/build/test-results/test/*.xml 2>/dev/null | head -1)"; collect "$W" boot405; } >> "$OUT/summary.txt"
rm -rf "$W"

# --- r15 ---
W="$(new_copy)"; add_probes "$W"
TJE="$W/infrastructure/src/main/java/com/example/taskmaster/infrastructure/TaskJpaEntity.java"
JTR="$W/infrastructure/src/main/java/com/example/taskmaster/infrastructure/JpaTaskRepository.java"
python3 - "$TJE" "$JTR" <<'PY'
import sys
tje, jtr = sys.argv[1], sys.argv[2]
s = open(tje).read()
s = s.rstrip().rstrip('}') + """
    void updateFrom(Task task) {
        this.title = task.getTitle();
        this.description = task.getDescription();
        this.dueDate = task.getDueDate();
        this.status = task.getStatus();
    }
}
"""
open(tje, 'w').write(s)
s = open(jtr).read()
old = """        return springDataRepository.save(TaskJpaEntity.fromDomain(task)).toDomain();"""
new = """        if (task.getId() != null) {
            TaskJpaEntity entity = springDataRepository.findById(task.getId())
                    .orElseThrow();
            entity.updateFrom(task);
            return entity.toDomain();
        }
        return springDataRepository.save(TaskJpaEntity.fromDomain(task)).toDomain();"""
assert s.count(old) == 1
open(jtr, 'w').write(s.replace(old, new))
PY
cp "$JTR" "$OUT/r15-JpaTaskRepository.java"
rc=$(run_logged "$W" "$OUT/r15.log" ./gradlew clean :infrastructure:test --tests '*QueryCountProbeTest' --console=plain)
{ echo "r15: rc=$rc"; collect "$W" r15 | grep R14; } >> "$OUT/summary.txt"
rm -rf "$W"

# --- r10 ---
W="$(new_copy)"
awk '/^    @Transactional$/ && !d { print "    // 記事 sec05 の「TaskServiceでの使用例」をそのまま置く"; print "    @Transactional(readOnly = true)"; print "    public Page<TaskResponse> findByStatus("; print "            TaskStatus status, int page, int size) {"; print "        Pageable pageable = PageRequest.of(page, size,"; print "                Sort.by(\"dueDate\").ascending());"; print "        return springDataRepo.findByStatus(status, pageable)"; print "                .map(TaskJpaEntity::toDomain)"; print "                .map(TaskResponse::from);"; print "    }"; print ""; d=1 } { print }' "$W/$SVC" > "$W/s.new" && mv "$W/s.new" "$W/$SVC"
rc=$(run_logged "$W" "$OUT/r10.log" ./gradlew :application:compileJava --console=plain)
{ echo "r10: rc=$rc"; grep -h -o 'error: [^<]*' "$OUT/r10.log" | sort | uniq -c | sed 's/^/  /' | head -6; } >> "$OUT/summary.txt"
rm -rf "$W"

# --- c1 ---
W="$(new_copy)"
awk '/^    @Transactional$/ && !d { print "    // 記事 sec01 のトランザクションスクリプト"; print "    @Transactional"; print "    public TaskResponse completeTaskScript(Long taskId) {"; print "        Task task = taskRepository.findById(taskId)"; print "                .orElseThrow(() -> new TaskNotFoundException(taskId));"; print "        if (task.getStatus() == com.example.taskmaster.domain.TaskStatus.DONE) {"; print "            throw new IllegalStateException(\"Already completed.\");"; print "        }"; print "        return TaskResponse.from(taskRepository.save(task));"; print "    }"; print ""; d=1 } { print }' "$W/$SVC" > "$W/s.new" && mv "$W/s.new" "$W/$SVC"
rc=$(run_logged "$W" "$OUT/c1.log" ./gradlew :application:compileJava --console=plain)
echo "c1: rc=$rc" >> "$OUT/summary.txt"
rm -rf "$W"
cat "$OUT/summary.txt"
