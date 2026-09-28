#!/usr/bin/env python3
"""M4: 同じ 3 件のテストを、Mockito だけで行う版（A）と Spring のコンテキストを起動する版（B）で測る。

1 回目は捨てる（デーモンのウォームアップ）。以降 N 回、奇数回は A→B、偶数回は B→A の順で測る。
記録するもの: 壁時計（./gradlew 全体）と、JUnit XML の testsuite の time 属性（テスト実行時間）。
"""
import csv, glob, json, re, statistics, subprocess, sys, time
from pathlib import Path

work, out, n = Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3])
VARIANTS = {"A": "TaskServiceTest", "B": "TaskServiceSpringContextTest"}
XML_DIR = work / "application/build/test-results/test"
OPTS = ["--console=plain", "--no-build-cache", "--no-configuration-cache", "--rerun-tasks", "-q"]

def run(variant):
    cls = VARIANTS[variant]
    for x in XML_DIR.glob("*.xml"):
        x.unlink()
    cmd = ["./gradlew", ":application:test", "--tests", f"com.example.taskmaster.application.{cls}", *OPTS]
    t0 = time.perf_counter()
    p = subprocess.run(cmd, cwd=work, capture_output=True, text=True)
    wall = time.perf_counter() - t0
    junit, tests = 0.0, 0
    for x in XML_DIR.glob(f"TEST-*{cls}.xml"):
        h = x.read_text()
        m = re.search(r'<testsuite [^>]*tests="(\d+)"[^>]*time="([\d.]+)"', h)
        tests += int(m.group(1)); junit += float(m.group(2))
    return p.returncode, round(wall, 3), round(junit, 3), tests

rows = []
for v in ("A", "B"):                                  # ウォームアップ（捨てる）
    rc, wall, junit, tests = run(v)
    rows.append({"iter": 0, "variant": v, "rc": rc, "wall_s": wall, "junit_s": junit, "tests": tests, "discarded": True})
for i in range(1, n + 1):
    order = ("A", "B") if i % 2 else ("B", "A")
    for v in order:
        rc, wall, junit, tests = run(v)
        rows.append({"iter": i, "variant": v, "rc": rc, "wall_s": wall, "junit_s": junit, "tests": tests, "discarded": False})

with open(out / "runs.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    w.writeheader(); w.writerows(rows)

kept = [r for r in rows if not r["discarded"]]
def med(v, k): return statistics.median(r[k] for r in kept if r["variant"] == v)
summary = {
    "n": n,
    "allRc0": all(r["rc"] == 0 for r in rows),
    "testsPerRun": sorted({r["tests"] for r in kept}),
    "median": {v: {"wall_s": med(v, "wall_s"), "junit_s": med(v, "junit_s")} for v in ("A", "B")},
}
summary["ratioB_over_A"] = {
    "wall": round(summary["median"]["B"]["wall_s"] / summary["median"]["A"]["wall_s"], 2),
    "junit": round(summary["median"]["B"]["junit_s"] / summary["median"]["A"]["junit_s"], 2),
}
# 揺れる量の代理（突合用）: どちらが速いか（順位）
summary["fasterByJunit"] = "A" if summary["median"]["A"]["junit_s"] < summary["median"]["B"]["junit_s"] else "B"
summary["fasterByWall"] = "A" if summary["median"]["A"]["wall_s"] < summary["median"]["B"]["wall_s"] else "B"
(out / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
print(json.dumps(summary, ensure_ascii=False))
