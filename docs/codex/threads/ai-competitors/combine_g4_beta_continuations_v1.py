"""Combine six helper-prepared Studio continuations without editing envelopes."""

import argparse
import json
from pathlib import Path


IDS = tuple(
    f"{genre}-4417-{mode}-second"
    for genre in ("adventure", "puzzle")
    for mode in ("reference", "synergy", "synergy_beta")
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputs", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit(f"Refusing to overwrite {args.output}")
    docs = [json.loads((args.inputs / f"{case_id}.json").read_text(encoding="utf-8")) for case_id in IDS]
    policy = docs[0]["policy"]
    if any(doc["policy"] != policy or len(doc["cases"]) != 1 or doc["cases"][0]["case_id"] != case_id for doc, case_id in zip(docs, IDS)):
        raise SystemExit("Prepared policies or case identities differ")
    combined = {"schema_version": "1", "policy": policy, "cases": [doc["cases"][0] for doc in docs]}
    args.output.write_text(json.dumps(combined, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(combined['cases'])} Studio-only continuations")


if __name__ == "__main__":
    main()
