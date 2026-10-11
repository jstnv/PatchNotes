"""Materialize the predeclared second-project cases from retained Studio envelopes."""

import json
import sys
from pathlib import Path


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: prepare_g2_envelope_v1.py PREFIX_BUNDLE OUTPUT_JSON")
    bundle = Path(sys.argv[1])
    output = Path(sys.argv[2])
    cases = []
    for seed in ("4417", "90210"):
        parent = bundle / "cases" / f"g2-prefix-{seed}"
        result = json.loads((parent / "result.json").read_text(encoding="utf-8"))
        if result["status"] != "completed" or result["final_release_count"] != 1:
            raise ValueError(f"invalid legal prefix for {seed}: {result['status']}")
        checkpoint = json.loads((parent / "studio_checkpoint.json").read_text(encoding="utf-8"))
        if checkpoint["kind"] != "campaign_studio":
            raise ValueError(f"not a Studio checkpoint: {seed}")
        for hands in (1, 2, 3):
            cases.append({
                "schema_version": "1",
                "case_id": f"g2-next-{seed}-d{hands}a{hands}",
                "initial": {"checkpoint": checkpoint},
                "max_commands": 60,
                "target_release_count": 2,
                "telemetry": True,
                "study": {"pair_id": f"g2-envelope-{seed}", "arm": f"d{hands}a{hands}"},
                "policy": {"config": {
                    "genre": "action", "theme": "fantasy", "name_prefix": "G2 Next",
                    "selection": "features_first",
                    "hands": {"design": hands, "alpha": hands, "beta": 2},
                }},
            })
    payload = {
        "schema_version": "1",
        "policy": {"script": "res://scripts/simulation/finite_fixture_policy.gd", "id": "finite-development-fixture", "version": "1"},
        "cases": cases,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(cases)} predeclared cases: {output}")


if __name__ == "__main__":
    main()
