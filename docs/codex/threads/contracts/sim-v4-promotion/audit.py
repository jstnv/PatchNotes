"""Independent compact audit of the pinned native Promotion sweep."""

from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
V3 = HERE.parent / "sim-v3"
PROJECT = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-20261007-v3\patch-notes")
HEAD = "b84d1a5b4e4957b044b4b52c41553cf611aff3ae"
CASES = {
    "crown": {
        "capture": "route-legacy-ordinary-0-0.bin",
        "hash": "83e8df43cb78f9913b634c67c55c71cfd697a3ea80e8af4b989b6556644c776c",
        "case": "crown-route-legacy-ordinary-0-0",
        "advance": 15000,
        "target": 9,
        "seed": 200929001,
        "caps": [0, 6, 12, 18],
        "current_cap": 12,
    },
    "neon": {
        "capture": "route-legacy-ordinary-0-1.bin",
        "hash": "5c19295b148c3aef24377423d36f24d24f06d4c0849ec94630d76c12ff415a33",
        "case": "neon-route-legacy-ordinary-0-1",
        "advance": 0,
        "target": 10,
        "seed": 200929000,
        "caps": [0, 10, 20, 30],
        "current_cap": 20,
    },
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    checks = 0
    failures: list[str] = []

    def check(condition: bool, label: str) -> None:
        nonlocal checks
        checks += 1
        if not condition:
            failures.append(label)

    manifest = json.loads((V3 / "source-manifest.json").read_text(encoding="utf-8"))
    check(manifest["head"] == HEAD, "Source revision")
    check(len(manifest["files"]) == 1046, "Pinned source file count")
    altered_analysis = {"patch-notes/analysis/feature_store_rebaseline_v1.gd"}
    for entry in manifest["files"]:
        if entry["path"] in altered_analysis:
            continue
        path = PROJECT / Path(entry["path"]).relative_to("patch-notes")
        check(path.is_file() and digest(path) == entry["sha256"], "Pinned " + entry["path"])
    for name, expected in {
        "task34_advance_v3.gd": "e6e163d5d9ef42d393b5563febdb8c9006785ac43954917993a3f254aa010970",
        "task34_cohort_advance_v3.gd": "44656d1b7aefbb975a4d28d406830686f92bc881e8ca235c0d48b06bbffa3824",
    }.items():
        check(digest(PROJECT / "analysis" / name) == expected, "Pinned harness " + name)
    run_state = (PROJECT / "scripts" / "run_state.gd").read_text(encoding="utf-8")
    check('if int(snapshot.get("awareness", -1)) >= 125:' in run_state,
          "Pinned Neon frozen release Awareness gate")
    check('"review": _capture_release_review(project)' in run_state
          and "_refresh_publisher_unlocks()" in run_state,
          "Pinned release snapshot and unlock refresh path")

    v3_rows = list(csv.DictReader((V3 / "summary.csv").open(newline="", encoding="utf-8")))
    output_rows: list[dict] = []
    native_checks = 0
    for publisher, spec in CASES.items():
        check(digest(V3 / spec["capture"]) == spec["hash"], publisher + " typed input")
        data = json.loads((HERE / (publisher + ".json")).read_text(encoding="utf-8"))
        check(data["source_head"] == HEAD and data["publisher"] == publisher, publisher + " output identity")
        check(data["failures"] == [] and data["checks"] > 0, publisher + " native checks")
        native_checks += data["checks"]
        check(len(data["results"]) == 2, publisher + " two timings")
        for case in data["results"]:
            timing = case["timing"]
            check(timing in {"early", "after_game4"}, publisher + " timing")
            check(case["advance_cents"] == spec["advance"] and case["target_scope"] == spec["target"]
                  and case["seed"] == spec["seed"] and case["policy"] == "ordinary", publisher + " fixed Contract")
            check(len(case["hand_signatures"]) == 2 and all(h["success"] for h in case["hand_signatures"]),
                  publisher + " legal hands")
            if publisher == "crown":
                check(case["neon_unlocked_before"] is False, "Crown route starts before Neon unlock")
            check([r["cap"] for r in case["sweep"]] == spec["caps"], publisher + " cap predeclaration")
            n, d = case["completion_fraction"]
            base = case["sweep"][0]
            check(base["awarded_points"] == 0 and base["earned_delta_cents"] == 0
                  and base["settled_delta_cents"] == 0 and base["cash_delta_cents"] == 0,
                  publisher + " zero-cap control")
            for row in case["sweep"]:
                cap = row["cap"]
                check(row["awarded_points"] == cap * n // d, publisher + " exact award fraction")
                check(row["cash_delta_cents"] == row["settled_delta_cents"], publisher + " settled cash identity")
                check(row["final"]["cycle"] == base["final"]["cycle"]
                      and row["final"]["arrears"] == base["final"]["arrears"]
                      and row["final"]["credit"] == base["final"]["credit"],
                      publisher + " common calendar and finance state")
                launches = row["launches"]
                check(sum(x["promotion"] for x in launches) + row["promotion_pending"] == row["awarded_points"],
                      publisher + " once-only award")
                check(len(launches) > 0 and launches[0]["cycle"] == base["next_launch"]["cycle"],
                      publisher + " matched first launch")
                check(row["next_launch_meets_neon_awareness_gate"]
                      == (row["next_launch"].get("awareness", -1) >= 125),
                      publisher + " conditional Neon threshold reading")
                if timing == "after_game4":
                    check(row["earned_delta_cents"] == row["settled_delta_cents"] == 0,
                          publisher + " Game 5 censored earnings")
                output_rows.append({
                    "publisher": publisher, "timing": timing, "cap": cap,
                    "awarded_points": row["awarded_points"],
                    "first_launch_cycle": row["next_launch"].get("cycle", ""),
                    "first_launch_awareness": row["next_launch"].get("awareness", ""),
                    "first_launch_month_one_units": row["next_launch"].get("month_one_units", ""),
                    "neon_unlocked_before": case["neon_unlocked_before"],
                    "next_launch_meets_neon_awareness_gate": row["next_launch_meets_neon_awareness_gate"],
                    "earned_delta_cents": row["earned_delta_cents"],
                    "settled_delta_cents": row["settled_delta_cents"],
                    "cash_delta_cents": row["cash_delta_cents"],
                    "end_cycle": row["final"]["cycle"],
                    "end_cash_cents": row["final"]["cash"],
                    "end_arrears_cents": row["final"]["arrears"],
                    "end_credit": row["final"]["credit"],
                    "contract_direct_cash_cents": case["direct_cash_cents"],
                })
            original = [r for r in v3_rows if r["case"] == spec["case"]
                        and r["publisher"] == publisher and r["timing"] == timing
                        and r["policy"] == "ordinary" and int(r["seed"]) == spec["seed"]
                        and int(r["target"]) == spec["target"]
                        and int(r["advance"]) == spec["advance"]]
            check(len(original) == 1, publisher + " Task 34 reference identity")
            if len(original) == 1:
                current = next(r for r in case["sweep"] if r["cap"] == spec["current_cap"])
                check(current["awarded_points"] == int(original[0]["promotion"]), publisher + " Task 34 Promotion parity")
                check(current["settled_delta_cents"] == int(original[0]["promotion_settled_delta"]),
                      publisher + " Task 34 settled parity")
                check(case["direct_cash_cents"] == int(original[0]["direct_cash"]),
                      publisher + " Task 34 direct cash parity")
                check(case["contract_final"]["cash"] == int(original[0]["final_cash"]),
                      publisher + " Task 34 Contract cash parity")

    out = {"source_head": HEAD, "native_checks": native_checks, "independent_checks": checks,
           "failures": failures, "route_count": 2, "timing_count": 4, "sweep_arms": len(output_rows)}
    (HERE / "audit.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    with (HERE / "summary.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(output_rows[0]))
        writer.writeheader()
        writer.writerows(output_rows)
    print(json.dumps(out))
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
