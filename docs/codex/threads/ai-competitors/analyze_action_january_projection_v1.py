"""Audit the declared one-Action c72 capture and projection blockers."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
SEEDS = ("5607", "5613")


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    rows = []
    problems = []
    for seed in SEEDS:
        folder = HERE / "sims" / f"one-action-january-{seed}-20261028-v15"
        report_path = folder / "prelude.json"
        capsule_path = folder / "prelude-capsule.json"
        report = read(report_path)
        capsule = read(capsule_path)
        v12 = read(HERE / "sims" / f"one-action-typed-midpoint-{seed}-20261028-v12" / "prelude.json")
        p = report["projection"]
        first = capsule["archive"][0]
        source = capsule["historical_source"]
        first_source_equal = (
            source["release_id"] == first["id"]
            and source["release_cycle"] == first["release_cycle"]
            and source["review_tenths"] == first["review_tenths"]
            and source["cores"] == first["cores"]
            and source["genre"] == first["genre"]
        )
        same_boundary = (
            report["january_boundary"]["state_digest"] == v12["january_boundary"]["state_digest"]
            and report["january_boundary"]["rng_digest"] == v12["january_boundary"]["rng_digest"]
            and report["january_boundary"]["cash_cents"] == v12["january_boundary"]["cash_cents"]
        )
        expected_checks = (
            p["run_capture_ok"] and p["development_capture_ok"] and p["restored_equal"]
            and all(p["restore_checks"].values())
            and p["tampered_cash_rejected"] and p["tampered_id_rejected"]
            and p["tampered_target_rejected"] and p["archive_unique"]
            and p["archive_all_pre1980"] and first_source_equal and same_boundary
        )
        if report["issue"] or report["final_cycle"] != 72 or not expected_checks:
            problems.append(f"{seed}: active capture or source audit failed")
        if not p["world_c0_rejected"] or not p["post_cycle_ok"] or p["old_sales_earned_units_delta"] <= 0:
            problems.append(f"{seed}: expected unprojected-world blocker not reproduced")
        if p["archive_count"] != len(report["releases"]):
            problems.append(f"{seed}: archive/release count differs")
        rows.append({
            "seed": seed, "phase": p["phase"], "active_project_id": p["active_project_id"],
            "archive_count": p["archive_count"], "first_source_equal": first_source_equal,
            "same_v12_boundary": same_boundary, "run_capture_ok": p["run_capture_ok"],
            "development_capture_ok": p["development_capture_ok"],
            "restore_checks": p["restore_checks"],
            "tamper_rejections": {
                "cash": p["tampered_cash_rejected"],
                "project_id": p["tampered_id_rejected"],
                "historical_target": p["tampered_target_rejected"],
            },
            "world_c0_rejected": p["world_c0_rejected"],
            "old_sales_earned_units_on_c73": p["old_sales_earned_units_delta"],
            "old_fans_delta_on_c73": p["old_fans_delta"],
            "c72_cash_cents": report["january_boundary"]["cash_cents"],
            "c72_fans": report["january_boundary"]["fans"],
            "report": str(report_path.relative_to(HERE)), "report_sha256": sha(report_path),
            "capsule": str(capsule_path.relative_to(HERE)), "capsule_sha256": sha(capsule_path),
        })
    replay = read(HERE / "sims/one-action-january-5607-replay-20261028-v15/replay.json")
    if not replay["replay"]["ok"] or replay["final_cycle"] != 72:
        problems.append("5607 fresh-process replay failed")
    output = {
        "status": "partial_capture_verified_full_projection_blocked",
        "seeds": list(SEEDS),
        "problems": problems,
        "capture_checks_pass": not problems,
        "full_january_projection_pass": False,
        "rows": rows,
    }
    target = HERE / "sims/action-january-projection-audit-20261028-v15.json"
    if target.exists():
        raise SystemExit("Refusing to overwrite retained audit")
    target.write_text(json.dumps(output, indent=2), encoding="utf-8")
    print(json.dumps({
        "capture_checks_pass": not problems,
        "full_january_projection_pass": False,
        "problems": problems,
        "rows": [{"seed": row["seed"], "phase": row["phase"],
                  "archive": row["archive_count"],
                  "old_sales_units": row["old_sales_earned_units_on_c73"]}
                 for row in rows],
    }))


if __name__ == "__main__":
    main()
