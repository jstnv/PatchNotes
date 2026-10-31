"""Audit frozen Review factors from the current two-rival 27-Scope checks."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import struct


VARIANCE = (-0.5, -0.25, 0.0, 0.25, 0.5)


def frozen_float(value: dict) -> float:
    return struct.unpack(">d", bytes.fromhex(value["f64"]))[0]


def review_round(value: float) -> float:
    return math.floor(max(0.0, min(10.0, value)) * 10.0 + 0.5) / 10.0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, action="append", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit("Output already exists")
    sources: set[str] = set()
    cases: list[dict] = []
    for path in args.input:
        raw = path.read_bytes()
        probe = json.loads(raw)
        sources.add(probe["source"])
        if probe["failures"] or probe["checks"] < 100 or probe["cycle"] != 20:
            raise SystemExit(f"Incomplete source check: {path}")
        releases: list[dict] = []
        for studio in probe["boundaries"]["20"]["world"]["studios"]:
            for item in studio["run"]["run"]["release_metadata"]:
                value = item["value"]
                review = value["review"]
                production = frozen_float(review["production_rating"])
                actual = frozen_float(review["final_review"])
                scope = int(review["scope"])
                required = int(review["required_scope"])
                bugs = int(review["remaining_bugs"])
                if required <= 0 or scope < 0 or bugs < 0:
                    raise SystemExit("Invalid frozen Scope/Bugs")
                completion = min(1.0, scope / required)
                bug_factor = max(0.25, min(1.0, 1.0 - bugs / required))
                base = production * completion * bug_factor
                matches = [v for v in VARIANCE if review_round(base + v) == actual]
                if len(matches) != 1:
                    raise SystemExit(f"Ambiguous Review variance: {item['key']} {matches}")
                variance = matches[0]
                releases.append({
                    "studio_id": studio["id"], "release_id": item["key"],
                    "release_cycle": int(value["release_cycle"]),
                    "genre": value["genre"], "review": actual,
                    "production_rating": production, "scope": scope,
                    "required_scope": required, "scope_completion": completion,
                    "remaining_bugs": bugs, "bug_factor": bug_factor,
                    "cores": [int(v) for v in review["cores"]],
                    "standards": [int(v) for v in review["standards"]],
                    "variance": variance,
                    "formula_actual": review_round(base + variance),
                    "zero_bugs_only": review_round(production * completion + variance),
                    "full_scope_only": review_round(production * bug_factor + variance),
                    "full_scope_zero_bugs": review_round(production + variance),
                    "development_cycles": int(review["development_cycles"]),
                })
        releases.sort(key=lambda row: (row["release_cycle"], row["studio_id"]))
        cases.append({"input": str(path), "input_sha256": hashlib.sha256(raw).hexdigest(),
                      "source_identity": probe["source"], "checks": probe["checks"],
                      "seed": probe["fixture"]["player"]["rng"][0]["value"]["seed"],
                      "rival_supply_scope": probe["scopes"], "releases": releases})
    if len(sources) != 1:
        raise SystemExit("Different gameplay source identities")
    output = {"status": "formula_only_diagnostic", "source_identity": next(iter(sources)),
              "cases": cases}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "source_identity": output["source_identity"],
                      "cases": len(cases), "releases": sum(len(case["releases"]) for case in cases)}))


if __name__ == "__main__":
    main()
