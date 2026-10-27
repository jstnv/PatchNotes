"""Read-only one-hand completion target screen; never edits game source."""

import csv
import hashlib
import itertools
import json
from pathlib import Path

here = Path(__file__).resolve().parent
root = here.parents[3]
inputs = {
    root / "patch-notes/data/card_ledger.json": "0F093B0BA907043120C3E6E529511322E6E0B99358ADF6D69C80D5C174CFC83C",
    here / "SIDESTREET-RELATIONSHIP-BRIEF-WITNESSES-2026-10-18-v1.json": "3D22C08E8C2991697475C614256DFA722694AEC2DB36E51768061738268A8B17",
    here / "sims/sidestreet-brief-observation-v6-run-01/experiment.log": "381739458882B850C34ECFE002FE3BBD4A39F85CF627D14D2F8BFDC7BC21D43F",
}
for path, expected in inputs.items():
    actual = hashlib.sha256(path.read_bytes()).hexdigest().upper()
    if actual != expected:
        raise RuntimeError(f"Source drift: {path}: {actual}")

ledger = {entry["id"]: entry for entry in json.loads((root / "patch-notes/data/card_ledger.json").read_text())}
rosters = json.loads((here / "SIDESTREET-RELATIONSHIP-BRIEF-WITNESSES-2026-10-18-v1.json").read_text())["witnesses"]
lines = (here / "sims/sidestreet-brief-observation-v6-run-01/experiment.log").read_text().splitlines()
deals = [json.loads(line.removeprefix("PN_SIDE_BRIEF_DEAL ")) for line in lines if line.startswith("PN_SIDE_BRIEF_DEAL ")]
if len(deals) != 2 or deals[0] != deals[1] or len(deals[0]["candidates"]) != 7:
    raise RuntimeError("V6 paired seven-card deal differs or is malformed")
visible = deals[0]["candidates"]
stats = ("graphics", "sound", "technology", "design")
targets = {"control_6_3": (6, 3), "trial_5_3": (5, 3), "trial_5_2": (5, 2)}


def score(hand, target):
    scope = sum(int(card["scope"]) for card in hand)
    multiplier = 3 if len({card["primary_stat"] for card in hand}) == 1 else 2
    cores = {name: 0 for name in stats}
    for card in hand:
        for prefix in ("primary", "secondary"):
            stat = card[f"{prefix}_stat"]
            if stat:
                cores[stat] += multiplier * int(card[f"{prefix}_value"])
    scope_target, core_target = target
    denominator = 4 * scope_target + 8 * core_target
    numerator = 4 * min(scope, scope_target) + sum(min(cores[name], 2 * core_target) for name in stats)
    completion = 10000 * numerator // denominator
    promise = max(0, 10000 - 5000 * max(0, scope - 6))
    if not 0 <= completion <= 10000 or not 0 <= promise <= 10000:
        raise RuntimeError("Grade outside [0,10000]")
    return scope, tuple(cores.values()), completion, promise, min(completion, promise)


def summarize(label, hands):
    rows = []
    for name, target in targets.items():
        values = [(hand, score(hand, target)) for hand in hands]
        full = [(hand, result) for hand, result in values if result[4] == 10000]
        best = max(values, key=lambda item: item[1][4])
        rows.append({
            "pool": label, "target": name, "choices": len(values),
            "promise_full": sum(result[3] == 10000 for _, result in values),
            "promise_partial": sum(0 < result[3] < 10000 for _, result in values),
            "promise_miss": sum(result[3] == 0 for _, result in values),
            "both_full": len(full), "max_combined_bp": best[1][4],
            "full_witness": ",".join(card["id"] for card in full[0][0]) if full else "",
            "best_witness": ",".join(card["id"] for card in best[0]),
        })
    return rows


rows = []
passes = [ledger[name] for name in ("graphics_pass", "sound_pass", "technology_pass", "design_pass")]
for specialty, entry in rosters.items():
    owned = [ledger[name] for name in entry["roster"]]
    hands = [features + renewal for n in range(5)
             for features in itertools.combinations(owned, n)
             for renewal in itertools.combinations_with_replacement(passes, 4 - n)]
    rows += summarize(specialty, hands)
visible_hands = []
for four in itertools.combinations(visible, 4):
    # Card values are taken from the legal deal, which includes a reusable pass.
    visible_hands.append(tuple({"id": c["definition"], **{k: c[k] for k in
        ("scope", "primary_stat", "primary_value", "secondary_stat", "secondary_value")}} for c in four))
if len(visible_hands) != 35:
    raise RuntimeError("Expected 35 visible choices")
rows += summarize("visible_sports_1104", visible_hands)

out = here / "SIDESTREET-RELATIONSHIP-BRIEF-COMPLETION-SCREEN-2026-10-18-v2.csv"
with out.open("w", newline="", encoding="utf-8") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
print(f"PASS {len(rows)} rows, {len(rosters)} rosters, {len(visible_hands)} visible choices")
for row in rows:
    print(row["pool"], row["target"], "both_full", row["both_full"], "max", row["max_combined_bp"], "witness", row["full_witness"])
print(out)
