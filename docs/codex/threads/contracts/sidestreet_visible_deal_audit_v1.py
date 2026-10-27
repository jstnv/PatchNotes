"""Read-only four-of-seven score projection from the frozen v5 visible deal."""

from __future__ import annotations

import csv
import hashlib
import itertools
import json
from pathlib import Path


here = Path(__file__).resolve().parent
bundle = here / "sims/sidestreet-brief-observation-v5-run-01"
log = bundle / "experiment.log"
lines = log.read_text(encoding="utf-8").splitlines()
deal_lines = [line.removeprefix("PN_SIDE_BRIEF_DEAL ") for line in lines if line.startswith("PN_SIDE_BRIEF_DEAL ")]
if len(deal_lines) != 1:
    raise RuntimeError(f"Expected one visible SideStreet deal, found {len(deal_lines)}")
deal = json.loads(deal_lines[0])
cards = deal["candidates"]
if len(cards) != 7 or [c["token"] for c in cards] != list(range(7)):
    raise RuntimeError("Unexpected seven-card candidate shape")
stats = ("graphics", "sound", "technology", "design")
rows = []
for chosen in itertools.combinations(cards, 4):
    ids = [c["definition"] for c in chosen]
    if len({c["definition"] for c in chosen if not c["renewable"]}) != sum(not c["renewable"] for c in chosen):
        raise RuntimeError("Duplicate nonrenewable Feature")
    scope = sum(int(c["scope"]) for c in chosen)
    multiplier = 3 if len({c["primary_stat"] for c in chosen}) == 1 else 2
    cores = {key: 0 for key in stats}
    for card in chosen:
        for prefix in ("primary", "secondary"):
            name = card[f"{prefix}_stat"]
            if name:
                cores[name] += multiplier * int(card[f"{prefix}_value"])
    numerator = 4 * min(scope, 6) + sum(min(cores[key], 6) for key in stats)
    completion = 10000 * numerator // 48
    promise = max(0, 10000 - 5000 * max(0, scope - 6))
    if not 0 <= completion <= 10000 or not 0 <= promise <= 10000:
        raise RuntimeError("Projected grade outside basis-point bound")
    rows.append({
        "ids": ",".join(ids), "scope": scope,
        "graphics_half": cores["graphics"], "sound_half": cores["sound"],
        "technology_half": cores["technology"], "design_half": cores["design"],
        "completion_bp": completion, "promise_bp": promise,
        "combined_bp": min(completion, promise),
        "scope_grade": "full" if promise == 10000 else "miss" if promise == 0 else "partial",
    })
if len(rows) != 35:
    raise RuntimeError("Expected 35 four-of-seven combinations")

csv_path = here / "SIDESTREET-RELATIONSHIP-BRIEF-VISIBLE-DEAL-2026-10-18-v1.csv"
with csv_path.open("w", newline="", encoding="utf-8") as output:
    writer = csv.DictWriter(output, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
summary = {
    "bundle": str(bundle.relative_to(here)).replace("\\", "/"),
    "experiment_log_sha256": hashlib.sha256(log.read_bytes()).hexdigest(),
    "offer_id": deal["offer_id"],
    "count": len(rows),
    "grades": {
        grade: sum(row["scope_grade"] == grade for row in rows)
        for grade in ("full", "partial", "miss")
    },
    "both_full": sum(row["combined_bp"] == 10000 for row in rows),
    "max_combined_bp": max(row["combined_bp"] for row in rows),
    "scope_range": [min(row["scope"] for row in rows), max(row["scope"] for row in rows)],
    "witnesses": {
        grade: next((row for row in rows if row["scope_grade"] == grade), None)
        for grade in ("full", "partial", "miss")
    },
}
json_path = here / "SIDESTREET-RELATIONSHIP-BRIEF-VISIBLE-DEAL-2026-10-18-v1.json"
json_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: v for k, v in summary.items() if k != "witnesses"}, indent=2))
for grade, witness in summary["witnesses"].items():
    print(grade, witness)
print(csv_path)
print(json_path)
