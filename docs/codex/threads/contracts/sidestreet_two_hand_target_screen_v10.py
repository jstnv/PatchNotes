"""Arithmetic-only target comparison over the pinned v9 legal second deals."""

import csv
import hashlib
import json
from pathlib import Path

here = Path(__file__).resolve().parent
source = here / "SIDESTREET-TWO-HAND-SCREEN-2026-10-18-v9.csv"
expected = "7DEFB98313EE6203F0FA53120CDAA9F76CD26A749D459CC4A20EB6715C850644"
actual = hashlib.sha256(source.read_bytes()).hexdigest().upper()
if actual != expected:
    raise RuntimeError(f"Input drift: {actual}")
with source.open(newline="", encoding="utf-8") as stream:
    rows = list(csv.DictReader(stream))
cases = ("sports-1104-first-scope5", "sports-1104-first-scope8")
if len(rows) != 70 or any(sum(row["case"] == case for row in rows) != 35 for case in cases):
    raise RuntimeError("Expected 35 choices per case")
out = []
stats = ("graphics", "sound", "technology", "design")
for case in cases:
    subset = [row for row in rows if row["case"] == case]
    for target in (9, 10, 11):
        projected = []
        for row in subset:
            scope = int(row["total_scope"])
            cores = [int(row[f"{name}_half"]) for name in stats]
            numerator = 4 * min(scope, target) + sum(min(core, 6) for core in cores)
            completion = 10000 * numerator // (4 * target + 24)
            promise = max(0, 10000 - 5000 * max(0, scope - target))
            combined = min(completion, promise)
            if not all(0 <= value <= 10000 for value in (completion, promise, combined)):
                raise RuntimeError("Projected grade out of bounds")
            if combined == 10000 and (scope != target or any(core < 6 for core in cores)):
                raise RuntimeError("Unexpected full-grade witness")
            projected.append({"row": row, "completion": completion, "promise": promise, "combined": combined})
        best = max(projected, key=lambda item: item["combined"])
        full = [item for item in projected if item["combined"] == 10000]
        item = {
            "case": case, "scope_target": target, "core_target": 3,
            "choices": len(projected),
            "promise_full": sum(item["promise"] == 10000 for item in projected),
            "promise_half": sum(item["promise"] == 5000 for item in projected),
            "promise_miss": sum(item["promise"] == 0 for item in projected),
            "combined_full": len(full),
            "max_combined_bp": best["combined"],
            "full_witness": full[0]["row"]["second_cards"] if full else "",
            "best_witness": best["row"]["second_cards"],
        }
        if item["promise_full"] + item["promise_half"] + item["promise_miss"] != 35:
            raise RuntimeError("Promise classes do not account for every choice")
        out.append(item)

path = here / "SIDESTREET-TWO-HAND-TARGETS-2026-10-18-v10.json"
path.write_text(json.dumps({"source_csv_sha256": expected, "summary": out}, indent=2) + "\n")
print(f"PASS {len(out)} declared case/target cells, {len(rows)} source choices")
for item in out:
    print(item["case"], item["scope_target"], "promise", item["promise_full"],
          item["promise_half"], item["promise_miss"], "combined_full",
          item["combined_full"], "max", item["max_combined_bp"], "full witness", item["full_witness"])
print(path)
