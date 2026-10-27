"""Compare fixed-start private rival worlds without conflating rule identities."""
import argparse
import json
from pathlib import Path


def read_case(folder, seed):
    report = json.loads((folder / "prestart-shadow.json").read_text(encoding="utf-8"))
    run = json.loads((folder / "prestart-shadow-run.json").read_text(encoding="utf-8"))
    log = (folder / "prestart-shadow.log").read_text(encoding="utf-8", errors="replace")
    if (not run["ok"] or run["process_exit"] != 0 or report["seed"] != seed
            or report["failures"] or report["blocked"] or report["final_cycle"] != 24
            or "SCRIPT ERROR" in log or "ERROR:" in log):
        raise ValueError(f"Incomplete or failed case: {folder}")
    return report, run


def main():
    parser = argparse.ArgumentParser()
    for label in ("a4417", "b4417", "a4423", "b4423"):
        parser.add_argument("--" + label, type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = {"schema_version": 1, "method": "different frozen gameplay revisions, regenerated equal January starts", "seeds": {}, "rows": []}
    for seed in ("4417", "4423"):
        a, arun = read_case(getattr(args, "a" + seed), seed)
        b, brun = read_case(getattr(args, "b" + seed), seed)
        if a["checkpoints"][0] != b["checkpoints"][0]:
            raise ValueError(f"Initial state/RNG differs in seed {seed}")
        left = {r["release_id"]: r for r in a["releases"]}
        right = {r["release_id"]: r for r in b["releases"]}
        if left.keys() != right.keys():
            raise ValueError(f"Different release identity sets in seed {seed}; compare censored rows separately")
        result["seeds"][seed] = {
            "initial_world_digest": a["checkpoints"][0]["world_digest"],
            "a_source_identity": a["source_identity"], "b_source_identity": b["source_identity"],
            "a_elapsed_seconds": arun["elapsed_seconds"], "b_elapsed_seconds": brun["elapsed_seconds"],
            "a_release_count": len(left), "b_release_count": len(right),
        }
        for release_id in sorted(left):
            x, y = left[release_id], right[release_id]
            xr, yr = x["review"], y["review"]
            result["rows"].append({
                "seed": seed, "release_id": release_id,
                "a_cycle": x["release_cycle"], "b_cycle": y["release_cycle"],
                "a_genre": x["genre"], "b_genre": y["genre"],
                "a_review": xr["final_review"], "b_review": yr["final_review"],
                "review_delta": round(yr["final_review"] - xr["final_review"], 3),
                "a_core": xr["cores"], "b_core": yr["cores"],
                "a_standards": xr["standards"], "b_standards": yr["standards"],
                "a_scope": [xr["scope"], xr["required_scope"]],
                "b_scope": [yr["scope"], yr["required_scope"]],
                "a_bugs": xr["remaining_bugs"], "b_bugs": yr["remaining_bugs"],
            })
    deltas = [r["review_delta"] for r in result["rows"]]
    result["summary"] = {
        "matched_releases": len(deltas), "changed_genre": sum(r["a_genre"] != r["b_genre"] for r in result["rows"]),
        "same_release_cycle": sum(r["a_cycle"] == r["b_cycle"] for r in result["rows"]),
        "better": sum(d > 0 for d in deltas), "equal": sum(d == 0 for d in deltas),
        "worse": sum(d < 0 for d in deltas), "mean_review_delta": round(sum(deltas) / len(deltas), 4),
        "a_reached_5_6": sum(r["a_review"] >= 5.6 for r in result["rows"]),
        "b_reached_5_6": sum(r["b_review"] >= 5.6 for r in result["rows"]),
    }
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result["summary"], sort_keys=True))


if __name__ == "__main__":
    main()
