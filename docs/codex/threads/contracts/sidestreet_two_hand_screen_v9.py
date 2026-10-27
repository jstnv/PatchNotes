"""Read-only second-deal combination screen from frozen v9 SideStreet evidence."""

import csv
import hashlib
import itertools
import json
from pathlib import Path

here = Path(__file__).resolve().parent
bundle = here / "sims/sidestreet-two-hand-v9-run-01"
expected = {
    "run-report.json": "9C68B9D07E02EE34AD98E32B2C4FBB5B6388F9C40121784E0DCA02E2834FB6EC",
    "experiment.log": "92EAFE2842737AF7763A6F0CF5E9A164F016DFC1D3E90544839578162A3947DC",
    "cases/sports-1104-first-scope5/studio_checkpoint.json": "DFECE325ECC8A9B00D72E998BE22B8D15FD846557D462D6D9E4B98E855E01165",
    "cases/sports-1104-first-scope8/studio_checkpoint.json": "8B72124C2D558DE60FF259FE33EF9E9BBA09D67CA433FDBA8AE8BAB818F523C6",
}
for relative, digest in expected.items():
    found = hashlib.sha256((bundle / relative).read_bytes()).hexdigest().upper()
    if found != digest:
        raise RuntimeError(f"Frozen input drift: {relative}: {found}")
report = json.loads((bundle / "run-report.json").read_text())
if report["frozen_source_identity"] != "b77115e69e2b056de2fb34eff8d30b97dee53bc4bb2b62d06c53bc41a3929b79":
    raise RuntimeError("Unexpected frozen source")
cases = ["sports-1104-first-scope5", "sports-1104-first-scope8"]
results = [json.loads((bundle / "cases" / case / "result.json").read_text()) for case in cases]
if (not all(item["ok"] and item["accepted_commands"] == 61 for item in results)
        or results[0]["initial_state"] != results[1]["initial_state"]
        or results[0]["initial_rng"] != results[1]["initial_rng"]):
    raise RuntimeError("Cases are not successful matched starts")

lines = (bundle / "experiment.log").read_text().splitlines()
def records(tag):
    return [json.loads(line.split(" ", 1)[1]) for line in lines if line.startswith(tag + " ")]

deals = records("PN_SIDE_BRIEF_DEAL")
selections = records("PN_SIDE_BRIEF_SELECTION")
first_states = records("PN_SIDE_BRIEF_FIRST_HAND")
if len(deals) != 4 or len(selections) != 4 or len(first_states) != 2:
    raise RuntimeError("Expected two cases with two deals and one first-hand observation each")
stats = ("graphics", "sound", "technology", "design")
targets = {"core3": 3, "core4": 4, "core6_current_cash_control": 6}
rows = []
summaries = []


def added_half_cores(cards):
    multiplier = 3 if len({card["primary_stat"] for card in cards}) == 1 else 2
    cores = {stat: 0 for stat in stats}
    for card in cards:
        for prefix in ("primary", "secondary"):
            stat = card[f"{prefix}_stat"]
            if stat:
                cores[stat] += multiplier * int(card[f"{prefix}_value"])
    return [cores[stat] for stat in stats]


for index, case in enumerate(cases):
    first_deal, second_deal = deals[index * 2:index * 2 + 2]
    first_selection, second_selection = selections[index * 2:index * 2 + 2]
    first_state = first_states[index]
    candidates = second_deal["candidates"]
    if (first_deal["hand_count"] != 0 or second_deal["hand_count"] != 1
            or first_selection["hand_count"] != 0 or second_selection["hand_count"] != 1
            or len(candidates) != 7 or len({c["token"] for c in candidates}) != 7):
        raise RuntimeError(f"Unexpected dealt candidates: {case}")
    first_scope = int(first_state["scope"])
    first_cores = [int(first_state["core_half_units"][str(i)]) for i in range(4)]
    checkpoint = json.loads((bundle / "cases" / case / "studio_checkpoint.json").read_text())
    final = checkpoint["studio_payload"]["run"]["sidestreet_results"][0]["value"]
    final_scope = int(final["scope"])
    final_cores = [int(item["value"]) for item in final["core_half_units"]]
    if int(final["completion_numerator"]) != 90:
        raise RuntimeError(f"Unexpected current completion: {case}")
    remaining = candidates.copy()
    selected = []
    for name in second_selection["cards"]:
        hit = next((card for card in remaining if card["definition"] == name), None)
        if hit is None:
            raise RuntimeError(f"Selected second card missing: {case}: {name}")
        selected.append(hit)
        remaining.remove(hit)
    actual_cores = [a + b for a, b in zip(first_cores, added_half_cores(selected))]
    if (first_scope + sum(int(card["scope"]) for card in selected) != final_scope
            or actual_cores != final_cores):
        raise RuntimeError(f"Card projection differs from actual committed result: {case}")
    for four in itertools.combinations(candidates, 4):
        scope = first_scope + sum(int(card["scope"]) for card in four)
        cores = [a + b for a, b in zip(first_cores, added_half_cores(four))]
        promise = max(0, 10000 - 2500 * max(0, scope - 12))
        row = {"case": case, "second_tokens": ",".join(str(card["token"]) for card in four),
               "second_cards": ",".join(card["definition"] for card in four),
               "first_scope": first_scope, "total_scope": scope,
               **{f"{stat}_half": value for stat, value in zip(stats, cores)},
               "promise_bp": promise}
        for label, core_target in targets.items():
            numerator = 4 * min(scope, 12) + sum(min(value, 2 * core_target) for value in cores)
            denominator = 48 + 8 * core_target
            completion = 10000 * numerator // denominator
            row[f"{label}_completion_bp"] = completion
            row[f"{label}_combined_bp"] = min(completion, promise)
        rows.append(row)
    case_rows = [row for row in rows if row["case"] == case]
    if len(case_rows) != 35:
        raise RuntimeError(f"Expected 35 four-token choices: {case}")
    for label in targets:
        key = f"{label}_combined_bp"
        best = max(case_rows, key=lambda row: row[key])
        summaries.append({"case": case, "target": label, "choices": len(case_rows),
                          "unique_card_multisets": len({tuple(sorted(row["second_cards"].split(","))) for row in case_rows}),
                          "promise_full": sum(row["promise_bp"] == 10000 for row in case_rows),
                          "promise_partial": sum(0 < row["promise_bp"] < 10000 for row in case_rows),
                          "promise_miss": sum(row["promise_bp"] == 0 for row in case_rows),
                          "combined_full": sum(row[key] == 10000 for row in case_rows),
                          "max_combined_bp": best[key], "best_second_cards": best["second_cards"],
                          "actual_second_cards": ",".join(second_selection["cards"]),
                          "actual_total_scope": final_scope})

csv_path = here / "SIDESTREET-TWO-HAND-SCREEN-2026-10-18-v9.csv"
with csv_path.open("w", newline="", encoding="utf-8") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
json_path = here / "SIDESTREET-TWO-HAND-SUMMARY-2026-10-18-v9.json"
json_path.write_text(json.dumps({"frozen_source_identity": report["frozen_source_identity"],
                                  "input_sha256": expected, "summary": summaries}, indent=2) + "\n")
print(f"PASS {len(cases)} matched cases, {len(rows)} token choices, {len(summaries)} target summaries")
for item in summaries:
    print(item["case"], item["target"], "promise", item["promise_full"], item["promise_partial"], item["promise_miss"],
          "combined_full", item["combined_full"], "max", item["max_combined_bp"], "best", item["best_second_cards"])
print(csv_path)
print(json_path)
