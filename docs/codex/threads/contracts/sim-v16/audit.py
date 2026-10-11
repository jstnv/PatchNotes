"""Independent, read-only audit of the middle-first Crown gate confirmation.

The script reads existing attempts and prints a JSON summary. It never runs
Godot, changes an attempt, or treats a constructed liquidity fixture as a
legal Starwave route. Use --output only for a new summary file.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[4]
EVIDENCE = REPO / "docs/codex/findings/starwave-implementation-v1"
REFERENCE = EVIDENCE / "native-v3/native-route.json"
SPECIALTIES = ("adventure", "role_playing", "strategy", "simulation", "sports")
CORE = ("graphics", "sound", "technology", "design")
RUN_ID = re.compile(r"\b[0-9a-f]{32}:")
MONEY_WORD = re.compile(r"\b(cash|afford|funds?|money|insufficient)\b", re.I)
checks = 0


def require(condition: bool, label: str) -> None:
    global checks
    checks += 1
    if not condition:
        raise AssertionError(label)


def read(path: Path) -> dict | list:
    return json.loads(path.read_text(encoding="utf-8"))


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalized(value):
    """Replace only the per-run prefix on generated project/offer/bill IDs."""
    if isinstance(value, str):
        return RUN_ID.sub("<run>:", value)
    if isinstance(value, list):
        return [normalized(item) for item in value]
    if isinstance(value, dict):
        return {normalized(key): normalized(item) for key, item in value.items()}
    return value


def source_gate() -> dict:
    local_path = HERE / "source-manifest.json"
    local = read(local_path)
    original_path = EVIDENCE / "source-manifest-v3.json"
    recovery = read(EVIDENCE / "source-pin-recovery-v3.json")
    require(recovery["complete"], "complete native-v3 source recovery")
    require(sha(original_path) == recovery["source_manifest_sha256"], "original native-v3 manifest hash")
    require(sha(original_path) == local["original_manifest_sha256"], "screen pins original native-v3 manifest")
    original = read(original_path)
    require(local["pinned_head"] == original["head"], "exact pinned HEAD")
    require(original["head"] == "41c87c76fb4d3c06a5332d93f0e7b0997007475d", "declared source revision")
    selected = {
        name.removeprefix("patch-notes/"): digest
        for name, digest in original["files"].items()
        if name.startswith("patch-notes/") and (
            name.removeprefix("patch-notes/") in {"project.godot", "icon.svg", "icon.svg.import"}
            or name.removeprefix("patch-notes/").startswith(("scripts/", "analysis/", "assets/", "data/", "resources/", "Scenes/", "scenes/"))
        )
    }
    require(selected == local["files"] and len(selected) == local["selected_file_count"], "complete selected runtime manifest")
    pin = Path(local["source"])
    copy = Path(local["analysis_copy"])
    require(pin.resolve() == Path(recovery["destination"]).resolve() / "patch-notes", "recovered pin location")
    for name, digest in selected.items():
        require(sha(pin / name) == digest, "pinned source drift: " + name)
        require(sha(copy / name) == digest, "analysis copy drift: " + name)
    require(sha(HERE / "middle_first_route.gd") == local["analysis_route_sha256"], "analysis route unchanged")
    require(sha(HERE / "run.py") == local["runner_sha256"], "runner unchanged")
    require(sha(copy / "scripts/debug/middle_first_route.gd") == local["installed_route_sha256"], "installed analysis route unchanged")
    require(local["installed_route_sha256"] == local["analysis_route_sha256"], "installed route matches declared route")
    imported = read(HERE / "import/command.json")
    require(imported["exit"] == 0 and not imported["errors"] and not imported["timeout"], "clean native project import")
    require(imported["source_manifest_sha256"] == sha(local_path), "import source manifest")
    require(read(HERE / "import/source-after.json") == {"pin_drift": [], "copy_drift": [], "route_drift": False, "runner_drift": False}, "import source drift")
    return {"manifest": local, "manifest_sha256": sha(local_path), "copy": copy, "head": original["head"]}


def ledger(finance: dict, label: str) -> None:
    cash = 0
    month_delta = defaultdict(int)
    for sequence, tx in enumerate(finance["transactions"], 1):
        require(tx["sequence"] == sequence, f"{label}: transaction order {sequence}")
        require(tx["cash_before_cents"] == cash, f"{label}: journal cash before {sequence}")
        cash += tx["cash_delta_cents"]
        require(cash == tx["cash_after_cents"] and cash >= 0, f"{label}: journal cash after {sequence}")
        month_delta[tx["month"]] += tx["cash_delta_cents"]
    require(cash == finance["cash_cents"], f"{label}: journal closing cash")
    prior = 0
    for row in finance["monthly_rows"]:
        month = row["month"]
        require(row["opening_cash_cents"] == prior, f"{label}: month {month} opening")
        require(row["cash_change_cents"] == month_delta[month], f"{label}: month {month} movement")
        require(row["closing_cash_cents"] == prior + month_delta[month], f"{label}: month {month} closing")
        require(row["net_profit_cents"] == row["operating_revenue_cents"] - row["operating_expenses_cents"], f"{label}: month {month} profit")
        for kind in ("rent", "payroll"):
            require(row[f"{kind}_due_cents"] == row[f"{kind}_paid_cents"] + row[f"{kind}_unpaid_cents"], f"{label}: month {month} {kind}")
        prior = row["closing_cash_cents"]
    require(prior == cash, f"{label}: monthly/journal cash")
    require(sum(a["settled"] for a in finance["actions"]) == sum(r["sales_settled_cents"] for r in finance["monthly_rows"]), f"{label}: settled sales")
    for bill in finance["obligations"]:
        require(bill["due_cents"] >= 0 and bill["paid_cents"] >= 0 and bill["unpaid_cents"] >= 0, f"{label}: nonnegative original bill")
        require(bill["due_cents"] == bill["paid_cents"] + bill["unpaid_cents"], f"{label}: original bill balance")
        require(sum(p["cents"] for p in bill["payments"]) == bill["paid_cents"], f"{label}: original bill payments")


def check_state(state: dict, label: str) -> None:
    require(state["cash_cents"] == state["finance"]["cash_cents"], f"{label}: state/finance cash")
    require(state["cycle"] == state["finance"]["last_cycle"], f"{label}: state/finance cycle")
    require(state["cash_cents"] >= 0, f"{label}: no synthetic negative balance")
    require(state["finance_report"]["cash_cents"] == state["cash_cents"], f"{label}: HUD finance cash")
    ledger(state["finance"], label)


def publisher(offer: str) -> str:
    if offer == "balanced_primitive_contract_v1":
        return "ironclad"
    for name in ("crown_quill", "neon_circuit", "starwave"):
        if offer.endswith(f":{name}:first"):
            return name
    raise AssertionError("unrecognized publisher offer: " + offer)


def card_audit(contract: dict, cards: dict, label: str) -> dict:
    kind = publisher(contract["offer_id"])
    require(len(contract["hands"]) == (3 if kind == "starwave" else 2), f"{label}: required hands")
    scope = 0
    scores = [0, 0, 0, 0]
    consumed: set[str] = set()
    retained: list[str] | None = None
    for index, hand in enumerate(contract["hands"], 1):
        require("stop" not in hand, f"{label}: completed hand {index}")
        draw, chosen = hand["draw"], hand["selected"]
        require(len(draw) == 7 and len(chosen) == 4, f"{label}: seven/four hand {index}")
        require(not (Counter(chosen) - Counter(draw)), f"{label}: selections from actual draw {index}")
        remaining = list(draw)
        for card_id in chosen:
            remaining.remove(card_id)
        require(len(remaining) == 3, f"{label}: retained three {index}")
        if retained is not None:
            require(draw[:3] == retained, f"{label}: prior retention order {index}")
        retained = remaining
        selected = [cards[card_id] for card_id in chosen]
        multiplier = 3 if len({card["primary_stat"] for card in selected}) == 1 else 2
        for card in selected:
            if not card["renewable"]:
                require(card["id"] in contract["pool"] and card["id"] not in consumed, f"{label}: owned finite Feature once")
                consumed.add(card["id"])
            scope += card["scope"]
            scores[CORE.index(card["primary_stat"])] += multiplier * card["primary_value"]
            if card["secondary_stat"]:
                scores[CORE.index(card["secondary_stat"])] += multiplier * card["secondary_value"]
        require(hand["after"]["cycle"] == hand["before"]["cycle"] + 1, f"{label}: hand {index} costs one cycle")
        require(hand["before"]["cash_cents"] >= 0 and hand["after"]["cash_cents"] >= 0, f"{label}: legal cash states")
    result = contract["result"]
    require(result["scope"] == scope and [result["cores"][str(i)] for i in range(4)] == scores, f"{label}: independent Scope/Core score")
    if kind == "ironclad":
        numerator = 4 * min(scope, 12) + sum(min(score, 12) for score in scores)
        advance, cap, denominator, promotion = 40000, 240000, 96, 0
        require(contract["terms"] == {}, f"{label}: ordinary Ironclad terms")
    else:
        terms = contract["terms"]
        if kind == "crown_quill":
            numerator = 2 * min(scope, 9) + sum(min(score, 8) for score in scores) + 2 * min(min(score, 8) for score in scores)
            advance, cap, denominator, promotion = 15000, 192000, 66, 12
        elif kind == "neon_circuit":
            totals = [sum(cards[feature]["primary_value"] for feature in contract["pool"] if cards[feature]["primary_stat"] == stat) for stat in CORE]
            focus = max(range(4), key=lambda i: totals[i])
            numerator = 2 * min(scope, 10) + sum((3 * min(score, 18) if i == focus else min(score, 4)) for i, score in enumerate(scores))
            advance, cap, denominator, promotion = 0, 156000, 86, 20
        else:
            numerator = 4 * min(scope, 14) + sum(min(score, 14) for score in scores)
            advance, cap, denominator, promotion = 0, 224000, 112, 0
        require(terms["advance_cents"] == advance and terms["cash_cents"] == cap and terms["denominator"] == denominator and terms["promotion"] == promotion, f"{label}: approved frozen terms")
    require(0 <= numerator <= denominator, f"{label}: numerator within exact cap")
    cash = (cap - advance) * numerator // denominator
    require(result["numerator"] == numerator and result["cash"] == advance + cash and result["promotion"] == promotion * numerator // denominator, f"{label}: exact independent completion/reward")
    require(contract["before"]["cycle"] == contract["accepted"]["cycle"], f"{label}: zero-cycle acceptance")
    require(contract["accepted"]["cash_cents"] - contract["before"]["cash_cents"] == advance, f"{label}: one acceptance receipt")
    actions = [a for a in contract["after"]["finance"]["actions"] if a["source_id"] == contract["offer_id"]]
    expected_deltas = ([advance] if advance else []) + [0] * (len(contract["hands"]) - 1) + [cash]
    expected_cycles = ([contract["accepted"]["cycle"]] if advance else []) + [h["after"]["cycle"] for h in contract["hands"]]
    expected_kinds = (["publisher_receipt"] if advance else []) + ["contract_hand"] * (len(contract["hands"]) - 1) + ["publisher_receipt" if cash else "contract_hand"]
    require(len(actions) == len(expected_deltas), f"{label}: acceptance and hand action count")
    require([a["direct_delta"] for a in actions] == expected_deltas, f"{label}: acceptance and completing-hand receipts only")
    require([a["cycle"] for a in actions] == expected_cycles, f"{label}: receipt and hand timing")
    require([a["kind"] for a in actions] == expected_kinds, f"{label}: journal kinds")
    receipt = [t for t in contract["after"]["finance"]["transactions"] if t["source_id"] == contract["offer_id"] and t["kind"] == "publisher_receipt"]
    expected_receipts = ([(contract["accepted"]["cycle"], advance)] if advance else []) + ([(contract["hands"][-1]["after"]["cycle"], cash)] if cash else [])
    require([(t["cycle"], t["cash_delta_cents"]) for t in receipt] == expected_receipts, f"{label}: exact transaction receipts before settlement")
    for index, hand in enumerate(contract["hands"], 1):
        prefix = [a for a in hand["after"]["finance"]["actions"] if a["source_id"] == contract["offer_id"]]
        expected_prefix = ([advance] if advance else []) + [0] * (index - 1) + ([cash] if index == len(contract["hands"]) else [0])
        require([a["direct_delta"] for a in prefix] == expected_prefix, f"{label}: no future receipt at hand {index}")
    return {"publisher": kind, "scope": scope, "cores_half_units": scores, "numerator": numerator, "payout_cents": advance + cash, "completion_receipt_cents": cash, "promotion": result["promotion"], "draws": [h["draw"] for h in contract["hands"]], "selections": [h["selected"] for h in contract["hands"]]}


def overdue_at(state: dict) -> list[dict]:
    return [
        {"bill_id": bill["bill_id"], "type": bill["expense_type"], "due_cycle": bill["due_cycle"], "unpaid_cents": bill["unpaid_cents"]}
        for bill in state["finance"]["obligations"]
        if bill["due_cycle"] <= state["cycle"] and bill["unpaid_cents"] > 0
    ]


def control(a: dict, reference: dict) -> None:
    require(a["valid"] and a["starwave_completed"], "Action 1104 legal control completes")
    require(len(a["releases"]) == 3, "Action 1104 first three releases")
    for index, (actual, expected) in enumerate(zip(a["releases"], reference["releases"][:3]), 1):
        for field in ("cycle", "final_review", "awareness", "cash_cents", "cores", "scope", "month_1_units", "genre"):
            require(actual[field] == expected[field], f"Action control release {index} {field}")
        require(normalized(actual["release_id"]) == normalized(expected["release_id"]), f"Action control release {index} ID")
    for stage in ("before_starwave", "after_starwave"):
        for field in ("cycle", "cash_cents", "fans"):
            require(a[stage][field] == reference[stage][field], f"Action control {stage} {field}")
    actual = [x for x in a["actions"] if x.get("phase") == "contract"]
    expected = [x for x in reference["actions"] if x.get("phase") == "contract"]
    require(len(actual) == len(expected) == 4, "Action control four native Contracts")
    for index, (left, right) in enumerate(zip(actual, expected), 1):
        require(normalized(left["offer_id"]) == normalized(right["offer_id"]), f"Action control Contract {index} offer")
        require(left["pool"] == right["pool"] and left["terms"] == right["terms"], f"Action control Contract {index} frozen pool/terms")
        require(left["result"] == right["result"], f"Action control Contract {index} score/reward")
        for field in ("before", "accepted", "after"):
            for item in ("cycle", "cash_cents"):
                require(left[field][item] == right[field][item], f"Action control Contract {index} {field} {item}")
        require(len(left["hands"]) == len(right["hands"]), f"Action control Contract {index} hand count")
        for hand_index, (one, two) in enumerate(zip(left["hands"], right["hands"]), 1):
            for field in ("draw", "selected"):
                require(normalized(one[field]) == normalized(two[field]), f"Action control Contract {index} hand {hand_index} {field}")
            for stage in ("before", "after"):
                for item in ("cycle", "cash_cents"):
                    require(one[stage][item] == two[stage][item], f"Action control Contract {index} hand {hand_index} {stage} {item}")


def audit_attempt(folder: Path, source: dict, cards: dict, reference: dict) -> dict:
    specialty, seed_text = folder.name.rsplit("-", 1)
    seed = int(seed_text)
    require(specialty in SPECIALTIES and seed in (1104, 4417), folder.name + ": declared specialty/seed")
    meta = read(folder / "attempt.json")
    command = read(folder / "command.json")
    drift = read(folder / "source-after.json")
    expected_drift = {"pin_drift": [], "copy_drift": [], "route_drift": False, "runner_drift": False}
    require(meta["source_after"] == drift == expected_drift, folder.name + ": no source drift")
    require(not meta["driver_failure"] and not meta["godot_errors"] and not command["errors"] and not command["timeout"], folder.name + ": no driver or Godot error")
    require(command["source_manifest_sha256"] == source["manifest_sha256"], folder.name + ": exact source manifest")
    require(command["route_sha256"] == source["manifest"]["analysis_route_sha256"] and command["runner_sha256"] == source["manifest"]["runner_sha256"], folder.name + ": exact analysis scripts")
    require(command["exit"] == meta["godot_exit"] and command["exit"] in (0, 1), folder.name + ": native process exit")
    require(f"--specialty={specialty}" in command["command"] and f"--seed={seed}" in command["command"], folder.name + ": declared process inputs")
    require("--headless" in command["command"] and "--script" in command["command"], folder.name + ": native route command")
    log_errors = [line for line in (folder / "godot.log").read_text(encoding="utf-8", errors="replace").splitlines()
                  if ("SCRIPT ERROR" in line or line.startswith("ERROR:") or "FAIL:" in line) and "root certificate store" not in line]
    require(not log_errors, folder.name + ": no hidden Godot errors")
    d = read(folder / "native-route.json")
    require(d["source"] == "native-v3" and d["seed"] == seed and d["specialty"] == d["project_genre"] == specialty, folder.name + ": native route identity")
    require(d["policy"] == "synergy" and d["first_release_band"] == "middle" and d["later_release_band"] == "slow" and d["contract_deal_seed"] == 31104 and d["traits"] == ["lean_production", "studio_buzz", "expensive_lease"], folder.name + ": declared fixed policy")
    require(d["initial"]["cash_cents"] == 565000, folder.name + ": genuine trait-start cash")
    require(not d["errors"] and d["valid"] == meta["native_valid"] and d["stop"] == meta["stop"] and (command["exit"] == 0) == d["valid"], folder.name + ": legal outcome versus process outcome")
    require(d["ledger_valid"], folder.name + ": native ledger validity flag")
    require([state["cycle"] for state in d["cycles"]] == list(range(1, d["final"]["cycle"] + 1)), folder.name + ": every productive boundary once")
    check_state(d["initial"], folder.name + " initial")
    for state in d["cycles"]:
        check_state(state, folder.name + f" cycle {state['cycle']}")
    check_state(d["final"], folder.name + " final")
    releases = d["releases"]
    for game in range(1, len(releases) + 1):
        counts = [sum(a.get("phase") == phase and a.get("game") == game for a in d["actions"]) for phase in ("design", "alpha", "beta")]
        require(counts == ([4, 5, 4] if game == 1 else [5, 6, 6]), folder.name + f": game {game} actual hand schedule")
        launches = [a for a in d["actions"] if a.get("phase") == "launch" and a.get("game") == game]
        require(len(launches) == 1 and launches[0]["success"] and not launches[0]["budget_curtailed"], folder.name + f": game {game} full legal launch")
    release_ids = [release["release_id"] for release in releases]
    require(len(release_ids) == len(set(release_ids)) and release_ids == d["foundation_release_ids"], folder.name + ": distinct native releases")
    for release in releases:
        require(release["genre"] == specialty and release["release_id"] in d["metadata"] and release["release_id"] in d["sales"], folder.name + ": real matching-Genre release")
    complete_contracts = [action for action in d["actions"] if action.get("phase") == "contract" and "result" in action]
    foundation = [action for action in complete_contracts if publisher(action["offer_id"]) != "starwave"]
    require(len({action["offer_id"] for action in complete_contracts}) == len(complete_contracts), folder.name + ": distinct completed offers")
    require(len(foundation) == d["foundation_contract_count"], folder.name + ": actual completed prerequisite count")
    contract_results = []
    for index, action in enumerate(complete_contracts, 1):
        contract_results.append(card_audit(action, cards, f"{folder.name} contract {index}"))
    earned = bool(d["offer_earned"])
    if earned:
        require(len(release_ids) >= 2 and len(foundation) >= 3, folder.name + ": Starwave earned from actual releases/Contracts")
        require(d["before_starwave"]["cycle"] >= releases[1]["cycle"], folder.name + ": offer after second release")
        require(d["before_checkpoint_valid"] and not d["before_checkpoint_error"], folder.name + ": genuine checkpoint capture")
        require(d["frozen_pool"] and set(d["frozen_pool"]).issubset(set(d["initial_owned_ids"])), folder.name + ": owned frozen Primitive pool")
    else:
        require(not any(publisher(action["offer_id"]) == "starwave" for action in complete_contracts), folder.name + ": no unearned Starwave completion")
    if d["stop"] == "no earned Crown offer":
        require(max((r["final_review"] for r in releases), default=0) < 7.0, folder.name + ": real Crown Review gate")
    if d["stop"] == "no earned Neon offer":
        require(max((r["awareness"] for r in releases), default=0) < 125, folder.name + ": real Neon launch Awareness gate")
    if d["stop"] == "no earned Starwave offer":
        require(len(release_ids) < 2 or len(foundation) < 3, folder.name + ": no unexplained missed Starwave gate")
    star = next((action for action in complete_contracts if publisher(action["offer_id"]) == "starwave"), None)
    if star:
        require(earned and star["pool"] == d["frozen_pool"], folder.name + ": accepted actual earned pool")
        require(d["starwave_completed"] and d["valid"] and not d["stop"] and not d["blockers"], folder.name + ": actual three-hand completion")
        require(d["completed_checkpoint_valid"] and not d["completed_checkpoint_error"], folder.name + ": completed native checkpoint")
        require(d["after_starwave"]["cycle"] == star["hands"][-1]["after"]["cycle"], folder.name + ": after Starwave stage")
    else:
        require(not d["starwave_completed"] and not d["valid"], folder.name + ": noncompletion not relabeled")
    window = []
    cash_block = None
    if earned:
        window.append(d["before_starwave"])
        for action in d["actions"]:
            if action.get("phase") == "contract" and publisher(action["offer_id"]) == "starwave":
                window.append(action["accepted"])
                window += [hand["after"] for hand in action["hands"][:2] if "after" in hand]
        if d["stop"].startswith("Starwave hand") and MONEY_WORD.search(str(d["final"].get("financial_block", ""))):
            cash_block = {"cycle": d["final"]["cycle"], "reason": d["final"]["financial_block"]}
    original_arrears = []
    seen_bills = set()
    for state in window:
        for bill in overdue_at(state):
            if bill["bill_id"] not in seen_bills:
                original_arrears.append({**bill, "observed_cycle": state["cycle"]})
                seen_bills.add(bill["bill_id"])
    all_states = [d["initial"], *d["cycles"], d["final"]]
    for action in d["actions"]:
        all_states.extend(action[key] for key in ("before", "accepted", "after") if isinstance(action.get(key), dict) and "cash_cents" in action[key])
    low = min((state["cash_cents"], state["cycle"]) for state in all_states)
    return {
        "specialty": specialty,
        "seed": seed,
        "outcome": "legal Starwave completion" if star else "legal foundation dropout" if not d["stop"].startswith("Starwave hand") else "legal Starwave hand dropout",
        "stop": d["stop"],
        "reviews": [r["final_review"] for r in releases],
        "launch_awareness": [r["awareness"] for r in releases],
        "completed_foundation_contracts": len(foundation),
        "offer_earned": earned,
        "starwave_completed": bool(star),
        "starwave": contract_results[-1] if star else None,
        "cash_low_cents": low[0],
        "cash_low_cycle": low[1],
        "pre_starwave_cash_cents": d["before_starwave"]["cash_cents"] if earned else None,
        "post_starwave_cash_cents": d["after_starwave"]["cash_cents"] if star else None,
        "cash_block": cash_block,
        "original_arrears_before_receipt": original_arrears,
        "genuine_advance_question": bool(cash_block or original_arrears),
        "final_credit": d["finance_report"]["credit"]["score"],
        "final_cycle": d["final"]["cycle"],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="New summary path; existing files are never replaced")
    args = parser.parse_args()
    source = source_gate()
    cards = {card["id"]: card for card in read(source["copy"] / "data/card_ledger.json")}
    reference = read(REFERENCE)
    folders = sorted((path for path in HERE.iterdir() if path.is_dir() and re.fullmatch(r"(?:adventure|role_playing|strategy|simulation|sports)-(?:1104|4417)", path.name)), key=lambda path: (SPECIALTIES.index(path.name.rsplit("-", 1)[0]), path.name))
    require(len(folders) == 10, "exact bounded confirmation attempt set")
    require(all(any(folder.name == specialty + "-1104" for folder in folders) for specialty in SPECIALTIES), "all five primaries present")
    names = {folder.name for folder in folders}
    for folder in folders:
        if folder.name.endswith("-4417"):
            primary = folder.name.removesuffix("-4417") + "-1104"
            require(primary in names and not read(HERE / primary / "attempt.json")["native_valid"], folder.name + ": fallback only after primary failure")
    attempts = [audit_attempt(folder, source, cards, reference) for folder in folders]
    summary = {
        "passed": True,
        "scope": "read-only middle-first native Crown/Starwave reachability confirmation",
        "source_head": source["head"],
        "source_manifest_sha256": source["manifest_sha256"],
        "original_native_v3_manifest_sha256": source["manifest"]["original_manifest_sha256"],
        "source_file_count": source["manifest"]["selected_file_count"],
        "reference_route_sha256": sha(REFERENCE),
        "control_match": None,
        "attempts": attempts,
        "legal_starwave_completions": sum(a["starwave_completed"] for a in attempts),
        "genuine_advance_questions": [a["specialty"] + "-" + str(a["seed"]) for a in attempts if a["genuine_advance_question"]],
        "independent_checks": checks,
        "limitations": [
            "The first pass ends at Starwave hand 3; no matched Game 4 opportunity-cost conclusion.",
            "Project Genre is matched to specialty, so roster and Genre rating effects are not isolated.",
            "A low cash balance alone is not a cash rescue; constructed adverse-liquidity fixtures are excluded.",
            "No advance candidate or final numerical tuning is approved by this audit.",
        ],
    }
    body = json.dumps(summary, indent=2) + "\n"
    if args.output:
        require(not args.output.exists(), "refuse to overwrite an existing result")
        args.output.write_text(body, encoding="utf-8")
    print(body, end="")


if __name__ == "__main__":
    main()
