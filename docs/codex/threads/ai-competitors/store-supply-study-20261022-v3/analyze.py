"""Read only: summarize the predeclared two-seed, three-arm Store probe."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path


THREAD = Path(__file__).resolve().parent.parent
SIMS = THREAD / "sims"
NAMES = {
    "4417": {"A": "store-supply-action-4417-A-v1", "B": "store-supply-action-4417-B-v1", "C": "store-supply-action-4417-C-v3"},
    "4418": {"A": "store-supply-action-4418-A-v1", "B": "store-supply-action-4418-B-v1", "C": "store-supply-action-4418-C-v1"},
}
WAYFINDER = "incumbent-wayfinder-works"
FEATURE = "16_bit_music"


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def owned_play(row: dict) -> bool:
    return row["request"] == "play" and any(
        card.get("definition") == FEATURE and card.get("token") in row["selected_tokens"]
        for card in row["candidates"]
    )


def summarize(folder: Path) -> dict:
    report_path = folder / "world-report.json"
    run_path = folder / "world-run.json"
    report, run = read(report_path), read(run_path)
    assert run["ok"] and report["failures"] == 0 and report["completed"]
    releases = [r for r in report["rival_release_details"] if r["studio_id"] == WAYFINDER]
    progress = [r for r in report["rival_progress"] if r["studio_id"] == WAYFINDER]
    choice = [r for r in report["rival_choices"] if r["studio_id"] == WAYFINDER]
    second = releases[1]["release_id"]
    second_choice = [r for r in choice if r["project_id"] == second]
    purchased = [r for r in report["store_records"] if r["action"].get("type") in ("admit_research", "research")]
    return {
        "folder": folder.name,
        "report_sha256": sha(report_path),
        "run_sha256": sha(run_path),
        "harness_sha256": run["harness_sha256"],
        "source_identity": report["source_identity"],
        "initial_state_digest": report["initial_state_digest"],
        "initial_rng": report["initial_rng"],
        "first_boundary_digest": report["first_boundary_digest"],
        "first_boundary_rng": report["first_boundary_rng"],
        "commands": report["commands"],
        "checks": report["checks"],
        "wayfinder_releases": releases,
        "second_release_feature_draws": len({r["sequence"] for r in second_choice if r["request"] == "play" and any(c.get("definition") == FEATURE for c in r["candidates"])}),
        "second_release_feature_plays": len({r["sequence"] for r in second_choice if owned_play(r)}),
        "store_commands": [r["action"]["type"] for r in purchased],
        "first_quote": report["store_records"][0]["quote"],
        "first_outstanding": report["store_records"][0]["outstanding"],
        "store_cash_trace": [[r["cycle"], r["cash_cents"], r["action"].get("type")] for r in report["store_records"][:4]],
        "final_cash_cents": progress[-1]["cash_cents"],
        "final_fans": progress[-1]["fans"],
        "minimum_observed_cash_cents": min(r["cash_cents"] for r in progress),
        "max_observed_unpaid_cents": max(sum(int(b["unpaid_cents"]) for b in r["outstanding"].get("bills", [])) for r in progress),
        "player_releases": [[r["cycle"], r["sales"]["review_tenths"]] for r in report["releases"]],
        "cpu_seconds": run["world_process"]["actual_process_cpu_seconds"],
        "checkpoint_bytes": (folder / "world-report.json.checkpoint.json").stat().st_size,
    }


def main() -> None:
    result = {seed: {arm: summarize(SIMS / name) for arm, name in arms.items()} for seed, arms in NAMES.items()}
    for seed, arms in result.items():
        for field in ("initial_state_digest", "initial_rng", "first_boundary_digest", "first_boundary_rng", "source_identity"):
            assert len({json.dumps(data[field], sort_keys=True) for data in arms.values()}) == 1, (seed, field)
    output = Path(__file__).with_name("analysis.json")
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    for seed, arms in result.items():
        print(seed, "PARITY", " ".join(
            f"{arm}:R2={data['wayfinder_releases'][1]['review_tenths']/10:.1f}@{data['wayfinder_releases'][1]['cycle']}"
            f",plays={data['second_release_feature_plays']},cash={data['final_cash_cents']}"
            for arm, data in arms.items()))
    print(output)


if __name__ == "__main__":
    main()
