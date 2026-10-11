"""Independent read-only audit of six source-matched Starwave continuations.

Reads the saved native traces; never runs Godot or changes a raw result. By
default the JSON summary is printed. --output writes only a new file.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re


HERE = Path(__file__).resolve().parent
V2 = HERE / "repair-v2"
V3 = HERE / "repair-v3"
RUN = HERE / "repair-v4"
REPO = HERE.parents[4]
V12 = HERE.parent / "sim-v12"
NATIVE = REPO / "docs/codex/findings/starwave-implementation-v1"
COHORTS = {
    "action-1104": ("action", 1104, "61f1c69c203c9e671e18fc749abac267b368ec3ac91e6b14139affa2db25d335"),
    "puzzle-4417": ("puzzle", 4417, "8c7c42f0edc205eefda55959d7e67f66fd1da0208e4160abf60a4ba972f91381"),
    "racing-1104": ("racing", 1104, "dde276dc491b4d5aff1b395f3db86776fae4839e5b98a28cef5ef3c6ce09559c"),
}
ARMS = ("starwave", "skip")
CORE = ("graphics", "sound", "technology", "design")
ENDPOINTS = (75, 77, 79)
RUN_ID = re.compile(r"\b[0-9a-f]{32}:")
checks = 0


def require(ok: bool, label: str) -> None:
    global checks
    checks += 1
    if not ok:
        raise AssertionError(label)


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def normal_id(value):
    if isinstance(value, str):
        return RUN_ID.sub("<run>:", value)
    if isinstance(value, list):
        return [normal_id(item) for item in value]
    if isinstance(value, dict):
        return {normal_id(key): normal_id(item) for key, item in value.items()}
    return value


def source_gate() -> dict:
    manifest_path = RUN / "source-manifest.json"
    local = read(manifest_path)
    original_path = NATIVE / "source-manifest-v3.json"
    recovery = read(NATIVE / "source-pin-recovery-v3.json")
    require(recovery["complete"] and sha(original_path) == recovery["source_manifest_sha256"], "complete original native-v3 pin")
    original = read(original_path)
    require(local["original_manifest_sha256"] == sha(original_path), "v13 original manifest identity")
    require(local["pinned_head"] == original["head"] == "41c87c76fb4d3c06a5332d93f0e7b0997007475d", "exact original revision")
    selected = {
        name.removeprefix("patch-notes/"): digest
        for name, digest in original["files"].items()
        if name.startswith("patch-notes/") and (
            name.removeprefix("patch-notes/") in {"project.godot", "icon.svg", "icon.svg.import"}
            or name.removeprefix("patch-notes/").startswith(("scripts/", "analysis/", "assets/", "data/", "resources/", "Scenes/", "scenes/"))
        )
    }
    require(selected == local["files"] and len(selected) == local["selected_file_count"], "complete runtime selection")
    pin, copy = Path(local["source"]), Path(local["analysis_copy"])
    require(pin.resolve() == (Path(recovery["destination"]) / "patch-notes").resolve(), "source pin location")
    for name, digest in selected.items():
        require(sha(pin / name) == digest, "original source drift: " + name)
        require(sha(copy / name) == digest, "v13 analysis copy drift: " + name)
    for script in ("cross_specialty_base.gd", "matched_continuation.gd"):
        require(sha(RUN / script) == local["analysis_scripts_sha256"][script], "analysis script unchanged: " + script)
        require(sha(copy / "scripts/debug" / script) == local["analysis_scripts_sha256"][script], "installed analysis script unchanged: " + script)
    require(sha(RUN / "run.py") == local["runner_sha256"], "v13 repair runner unchanged")
    require(local["inputs"] == {cohort: data[2] for cohort, data in COHORTS.items()}, "all predeclared payload hashes")
    for cohort, (_, _, digest) in COHORTS.items():
        require(sha(RUN / "inputs" / f"{cohort}.payload.json") == digest, cohort + ": copied input bytes")
        require(sha(V12 / cohort / "before-starwave.payload.json") == digest, cohort + ": genuine v12 input bytes")
        prior = read(V12 / cohort / "attempt.json")
        require(prior["native_valid"] and not prior["driver_failure"], cohort + ": v12 legal foundation")
        prior_trace = read(V12 / cohort / "native-route.json")
        require(prior_trace["offer_earned"] and prior_trace["starwave_completed"] and prior_trace["before_starwave"]["cycle"] == 54, cohort + ": v12 earned offer at cycle 54")
    imported = read(RUN / "import/command.json")
    require(imported["exit"] == 0 and not imported["timeout"] and not imported["errors"], "clean v13 Godot import")
    require(imported["source_manifest_sha256"] == sha(manifest_path), "import source manifest")
    clean = {"pin_drift": [], "copy_drift": [], "script_drift": [], "installed_script_drift": [], "input_drift": [], "runner_drift": False}
    require(read(RUN / "import/source-after.json") == clean, "import source/input drift")
    parse = read(RUN / "parse-check/command.json")
    require(parse["exit"] == 1 and not parse["timeout"] and not parse["errors"], "controlled repair parse gate exit")
    require(read(RUN / "parse-check/parse-result.json")["stop"] == "undeclared arm or specialty", "repair script loads without parse error")
    require(read(RUN / "parse-check/source-after.json") == clean, "parse gate source/input drift")
    first_manifest_path = HERE / "source-manifest.json"
    first_manifest = read(first_manifest_path)
    first_folder = HERE / "action-1104-starwave"
    first_attempt, first_command, first_drift = (read(first_folder / name) for name in ("attempt.json", "command.json", "source-after.json"))
    require(first_attempt["driver_failure"] and not first_attempt["native_valid"] and first_attempt["godot_exit"] == 1, "original attempt is technical failure")
    require(first_attempt["stop"] == "native output missing" and first_command["source_manifest_sha256"] == sha(first_manifest_path), "original attempt manifest and absent native result")
    require(first_attempt["source_after"] == first_drift == clean, "original technical failure had no source drift")
    require(any("Parse Error: Cannot infer the type of \"cycle\"" in line for line in first_attempt["godot_errors"]), "original parse error recorded")
    v2_manifest_path = V2 / "source-manifest.json"
    v2_manifest = read(v2_manifest_path)
    v2_folder = V2 / "action-1104-starwave"
    v2_attempt, v2_command, v2_drift, v2_trace = (read(v2_folder / name) for name in ("attempt.json", "command.json", "source-after.json", "matched-route.json"))
    require(not v2_attempt["driver_failure"] and not v2_attempt["native_valid"] and v2_attempt["godot_exit"] == 1, "v2 adapter dropout, not a successful paired route")
    require(v2_attempt["stop"] == v2_trace["stop"] == "Game-5 initial priority commit rejected", "v2 exact adapter stop")
    require(v2_trace["initial_typed_parity"] and v2_trace["ledger_valid"] and v2_trace["game4_launch"]["cycle"] == 75, "v2 genuine hydrated Game 4 prefix")
    require(set(v2_trace["endpoints"]) == {"75"} and v2_trace["final"]["cycle"] == 76, "v2 stopped before matched Game 5 endpoints")
    require(v2_attempt["source_after"] == v2_drift == clean and v2_command["source_manifest_sha256"] == sha(v2_manifest_path), "v2 adapter revision/source provenance")
    v3_manifest_path = V3 / "source-manifest.json"
    v3_manifest = read(v3_manifest_path)
    v3_folder = V3 / "action-1104-starwave"
    v3_attempt, v3_command, v3_drift, v3_trace = (read(v3_folder / name) for name in ("attempt.json", "command.json", "source-after.json", "matched-route.json"))
    require(not v3_attempt["driver_failure"] and not v3_attempt["native_valid"] and v3_attempt["godot_exit"] == 1, "v3 adapter dropout, not paired balance data")
    require(v3_attempt["stop"] == v3_trace["stop"] == "Game-5 initial priority commit rejected", "v3 exact adapter stop")
    require(v3_trace["initial_typed_parity"] and v3_trace["ledger_valid"] and v3_trace["game4_launch"]["cycle"] == 75, "v3 genuine hydrated Game 4 prefix")
    require(set(v3_trace["endpoints"]) == {"75"} and v3_trace["final"]["cycle"] == 76, "v3 stopped before matched Game 5 endpoints")
    require(v3_attempt["source_after"] == v3_drift == clean and v3_command["source_manifest_sha256"] == sha(v3_manifest_path), "v3 adapter revision/source provenance")
    manifests = (first_manifest, v2_manifest, v3_manifest, local)
    require(len({m["analysis_scripts_sha256"]["cross_specialty_base.gd"] for m in manifests}) == 1, "all revisions keep unchanged base route")
    require(len({m["analysis_scripts_sha256"]["matched_continuation.gd"] for m in manifests}) == 4, "four distinct analysis route versions")
    require(all(m["files"] == local["files"] and m["inputs"] == local["inputs"] for m in manifests), "all revisions use identical runtime/input bytes")
    return {"manifest": local, "manifest_sha256": sha(manifest_path), "copy": copy, "clean_drift": clean,
            "original_technical_failure": {"attempt": str(first_folder), "manifest_sha256": sha(first_manifest_path),
                                           "runner_sha256": first_manifest["runner_sha256"],
                                           "analysis_scripts_sha256": first_manifest["analysis_scripts_sha256"],
                                           "godot_exit": first_attempt["godot_exit"], "reason": first_attempt["godot_errors"]},
            "v2_adapter_failure": {"attempt": str(v2_folder), "manifest_sha256": sha(v2_manifest_path),
                                   "runner_sha256": v2_manifest["runner_sha256"],
                                   "analysis_scripts_sha256": v2_manifest["analysis_scripts_sha256"],
                                   "stop": v2_attempt["stop"], "last_legal_cycle": v2_trace["final"]["cycle"]},
            "v3_adapter_failure": {"attempt": str(v3_folder), "manifest_sha256": sha(v3_manifest_path),
                                   "runner_sha256": v3_manifest["runner_sha256"],
                                   "analysis_scripts_sha256": v3_manifest["analysis_scripts_sha256"],
                                   "stop": v3_attempt["stop"], "last_legal_cycle": v3_trace["final"]["cycle"]},
            "repair": {"manifest_sha256": sha(manifest_path), "runner_sha256": local["runner_sha256"],
                       "analysis_scripts_sha256": local["analysis_scripts_sha256"]}}


def ledger(finance: dict, label: str) -> None:
    cash = 0
    month_delta = defaultdict(int)
    for index, transaction in enumerate(finance["transactions"], 1):
        require(transaction["sequence"] == index, f"{label}: journal sequence {index}")
        require(transaction["cash_before_cents"] == cash, f"{label}: journal cash before {index}")
        cash += transaction["cash_delta_cents"]
        require(cash == transaction["cash_after_cents"] and cash >= 0, f"{label}: journal cash after {index}")
        month_delta[transaction["month"]] += transaction["cash_delta_cents"]
    require(cash == finance["cash_cents"], f"{label}: closing cash")
    prior = 0
    for row in finance["monthly_rows"]:
        month = row["month"]
        require(row["opening_cash_cents"] == prior, f"{label}: month {month} opening")
        require(row["cash_change_cents"] == month_delta[month], f"{label}: month {month} cash movement")
        require(row["closing_cash_cents"] == prior + month_delta[month], f"{label}: month {month} closing")
        require(row["net_profit_cents"] == row["operating_revenue_cents"] - row["operating_expenses_cents"], f"{label}: month {month} profit")
        for kind in ("rent", "payroll"):
            require(row[kind + "_due_cents"] == row[kind + "_paid_cents"] + row[kind + "_unpaid_cents"], f"{label}: month {month} {kind}")
        prior = row["closing_cash_cents"]
    require(prior == cash, f"{label}: monthly/journal cash")
    require(sum(a["settled"] for a in finance["actions"]) == sum(row["sales_settled_cents"] for row in finance["monthly_rows"]), f"{label}: settled sales actions/rows")
    for bill in finance["obligations"]:
        require(bill["due_cents"] >= 0 and bill["paid_cents"] >= 0 and bill["unpaid_cents"] >= 0, f"{label}: nonnegative original bill")
        require(bill["due_cents"] == bill["paid_cents"] + bill["unpaid_cents"], f"{label}: original bill balance")
        require(sum(p["cents"] for p in bill["payments"]) == bill["paid_cents"], f"{label}: original bill payment history")


def endpoint(state: dict, cycle: int, label: str) -> dict:
    require(state["cycle"] == cycle and state["state"]["cycle"] == cycle, f"{label}: common calendar cycle")
    require(state["cash_cents"] == state["state"]["cash_cents"] == state["finance"]["cash_cents"] == state["finance_report"]["cash_cents"], f"{label}: cash across four captures")
    require(state["finance"]["last_cycle"] == cycle and state["finance_valid"], f"{label}: typed finance at cycle")
    require(state["project_cycle"] >= -1 and state["project_scope"] >= 0, f"{label}: actual project work")
    require(state["fans"] == state["fanbase"]["fans"], f"{label}: Fan snapshot")
    require(state["released_ids"] == list(state["sales"]), f"{label}: all released sales present")
    require(state["portfolio_settled_cents"] == sum(item["settled_cents"] for item in state["sales"].values()), f"{label}: exact portfolio settlement")
    require(state["portfolio_settled_cents"] <= sum(item["entitlement_cents"] for item in state["sales"].values()), f"{label}: no settlement ahead of entitlement")
    ledger(state["finance"], label)
    overdue = [
        {"id": bill["bill_id"], "type": bill["expense_type"], "due_cycle": bill["due_cycle"], "unpaid_cents": bill["unpaid_cents"]}
        for bill in state["finance"]["obligations"]
        if bill["due_cycle"] <= cycle and bill["unpaid_cents"] > 0
    ]
    return {"cycle": cycle, "cash_cents": state["cash_cents"], "settled_portfolio_cents": state["portfolio_settled_cents"],
            "earned_entitlement_cents": sum(item["entitlement_cents"] for item in state["sales"].values()),
            "project_cycle": state["project_cycle"], "project_scope": state["project_scope"],
            "project_cores": state["project_cores"], "completed_contracts": state["completed_contracts"],
            "overdue_original_bills": overdue, "credit": state["finance_report"]["credit"]["score"],
            "pending_promotion": state["pending_promotion_awards"], "promotion_consumed": state["promotion_consumed"]}


def starwave_card_audit(contract: dict, cards: dict, label: str) -> dict:
    require(contract["offer_id"].endswith(":starwave:first") and len(contract["hands"]) == 3, label + ": actual Starwave offer/three hands")
    require(contract["terms"] == {"advance_cents": 0, "cash_cents": 224000, "denominator": 112, "promotion": 0, "required_hands": 3, "scope": 14}, label + ": frozen approved terms")
    require(contract["accepted"]["cycle"] == contract["before"]["cycle"] and contract["accepted"]["cash_cents"] == contract["before"]["cash_cents"], label + ": zero advance and cycle")
    scope, cores, exhausted, retained = 0, [0, 0, 0, 0], set(), None
    for index, hand in enumerate(contract["hands"], 1):
        draw, chosen = hand["draw"], hand["selected"]
        require(len(draw) == 7 and len(chosen) == 4 and not (Counter(chosen) - Counter(draw)), f"{label}: seven/four legal draw {index}")
        remainder = list(draw)
        for card_id in chosen:
            remainder.remove(card_id)
        require(len(remainder) == 3, f"{label}: three retained {index}")
        if retained is not None:
            require(draw[:3] == retained, f"{label}: exact prior retention {index}")
        retained = remainder
        selected = [cards[card_id] for card_id in chosen]
        multiplier = 3 if len({card["primary_stat"] for card in selected}) == 1 else 2
        for card in selected:
            if not card["renewable"]:
                require(card["id"] in contract["pool"] and card["id"] not in exhausted, f"{label}: owned finite Feature once")
                exhausted.add(card["id"])
            scope += card["scope"]
            cores[CORE.index(card["primary_stat"])] += multiplier * card["primary_value"]
            if card["secondary_stat"]:
                cores[CORE.index(card["secondary_stat"])] += multiplier * card["secondary_value"]
        require(hand["after"]["cycle"] == hand["before"]["cycle"] + 1, f"{label}: actual productive hand {index}")
    n = 4 * min(scope, 14) + sum(min(core, 14) for core in cores)
    payout = 224000 * n // 112
    require(contract["result"] == {"cash": payout, "cores": {str(i): cores[i] for i in range(4)}, "numerator": n, "promotion": 0, "scope": scope}, label + ": independent score and exact payout")
    actions = [a for a in contract["after"]["finance"]["actions"] if a["source_id"] == contract["offer_id"]]
    require(len(actions) == 3 and [a["direct_delta"] for a in actions] == [0, 0, payout], label + ": zero early receipts and hand3 payment")
    require([a["cycle"] for a in actions] == [hand["after"]["cycle"] for hand in contract["hands"]], label + ": exact hand cycle timing")
    require([a["kind"] for a in actions] == ["contract_hand", "contract_hand", "publisher_receipt" if payout else "contract_hand"], label + ": finance action kinds")
    receipt = [t for t in contract["after"]["finance"]["transactions"] if t["source_id"] == contract["offer_id"] and t["kind"] == "publisher_receipt"]
    require([(t["cycle"], t["cash_delta_cents"]) for t in receipt] == ([(contract["hands"][-1]["after"]["cycle"], payout)] if payout else []), label + ": exact third-hand transaction")
    if receipt:
        final_cycle = receipt[0]["cycle"]
        require(all(tx["sequence"] > receipt[0]["sequence"] for tx in contract["after"]["finance"]["transactions"] if tx["cycle"] == final_cycle and tx is not receipt[0]), label + ": receipt precedes same-cycle settlement/bills")
    return {"scope": scope, "cores_half_units": cores, "numerator": n, "cash_cents": payout,
            "hand_cycles": [hand["after"]["cycle"] for hand in contract["hands"]],
            "draws": [hand["draw"] for hand in contract["hands"]], "selected": [hand["selected"] for hand in contract["hands"]]}


def audit_arm(cohort: str, arm: str, source: dict, cards: dict) -> tuple[dict, dict]:
    specialty, seed, digest = COHORTS[cohort]
    folder = RUN / f"{cohort}-{arm}"
    meta, command, drift = (read(folder / name) for name in ("attempt.json", "command.json", "source-after.json"))
    require(meta["cohort"] == cohort and meta["specialty"] == specialty and meta["seed"] == seed and meta["arm"] == arm and meta["input_sha256"] == digest, f"{cohort} {arm}: exact declared attempt")
    require(meta["source_after"] == drift == source["clean_drift"], f"{cohort} {arm}: no source/input drift")
    require(not meta["driver_failure"] and not meta["godot_errors"] and not command["errors"] and not command["timeout"], f"{cohort} {arm}: no driver/engine error")
    require(command["exit"] == meta["godot_exit"] and command["exit"] in (0, 1), f"{cohort} {arm}: process exit identity")
    require(command["source_manifest_sha256"] == source["manifest_sha256"] and command["runner_sha256"] == source["manifest"]["runner_sha256"], f"{cohort} {arm}: pinned source/runner")
    require(command["analysis_scripts_sha256"] == source["manifest"]["analysis_scripts_sha256"], f"{cohort} {arm}: pinned analysis scripts")
    for item in (f"--specialty={specialty}", f"--seed={seed}", f"--arm={arm}", "--headless", "--script"):
        require(item in command["command"], f"{cohort} {arm}: native command {item}")
    require(f"--input={RUN / 'inputs' / (cohort + '.payload.json')}" in command["command"], f"{cohort} {arm}: exact checkpoint input path")
    log_errors = [line for line in (folder / "godot.log").read_text(encoding="utf-8", errors="replace").splitlines()
                  if ("SCRIPT ERROR" in line or line.startswith("ERROR:") or "FAIL:" in line) and "root certificate store" not in line]
    require(not log_errors, f"{cohort} {arm}: no hidden engine errors")
    d = read(folder / "matched-route.json")
    payload = read(RUN / "inputs" / f"{cohort}.payload.json")
    require(d["arm"] == arm and d["specialty"] == specialty and d["seed"] == seed and d["input_sha256"] == digest, f"{cohort} {arm}: native input identity")
    require(d["initial_typed_parity"] and d["initial_checkpoint"] == payload, f"{cohort} {arm}: recaptured typed checkpoint parity")
    require(d["policy"] == "synergy" and d["game4_seed"] == seed + 1500000 and d["game5_seed"] == seed + 2000000, f"{cohort} {arm}: predeclared route seeds/policy")
    require(d["valid"] == meta["native_valid"] and d["stop"] == meta["stop"] and (command["exit"] == 0) == d["valid"], f"{cohort} {arm}: native outcome/exit parity")
    require(not d["errors"] and d["ledger_valid"], f"{cohort} {arm}: native error-free ledger")
    before = d["before"]
    require(before["cycle"] == before["state"]["cycle"] == int(payload["run"]["completed_run_cycles"]) == 54, f"{cohort} {arm}: cycle-54 Studio foundation")
    require(before["cash_cents"] == int(payload["run"]["cash_cents"]), f"{cohort} {arm}: initial cash typed parity")
    require(before["fans"] == int(payload["run"]["fanbase"]["fans"]), f"{cohort} {arm}: initial Fan count typed parity")
    require(before["finance"]["cash_cents"] == before["cash_cents"] and before["finance"]["last_cycle"] == 54, f"{cohort} {arm}: initial finance state")
    require(before["rng"] == d["initial_rng"], f"{cohort} {arm}: initial RNG capture")
    require(len(before["released_ids"]) == 3 and before["completed_contracts"] == 3, f"{cohort} {arm}: real releases/contracts")
    require(any(str(offer).endswith(":starwave:first") for offer in before["pending_offers"]), f"{cohort} {arm}: earned pending Starwave")
    require(before["portfolio_settled_cents"] == sum(record["settled_cents"] for record in before["sales"].values()), f"{cohort} {arm}: initial portfolio settlement")
    ledger(before["finance"], f"{cohort} {arm} before")
    prior = read(V12 / cohort / "native-route.json")
    require(before["cash_cents"] == prior["before_starwave"]["cash_cents"] and before["fans"] == prior["before_starwave"]["fans"], f"{cohort} {arm}: v12 foundation economics")
    allowed = {"contract", "predevelopment", "design", "alpha", "beta", "launch", "design_priority"}
    require(all(action.get("phase") in allowed for action in d["actions"]), f"{cohort} {arm}: no unplanned Store/Bank/hire/campaign actions")
    require(all(action.get("success", True) and not action.get("stop") for action in d["actions"]), f"{cohort} {arm}: successful recorded native actions")
    contracts = [action for action in d["actions"] if action.get("phase") == "contract"]
    star = None
    if arm == "starwave":
        require(len(contracts) == 1, f"{cohort}: one native Starwave Contract")
        star = starwave_card_audit(contracts[0], cards, f"{cohort} Starwave")
        require(d["starwave_result"] == contracts[0]["result"] and d["starwave_hands"] == contracts[0]["hands"], f"{cohort}: preserved actual three hands")
        require(d["after_starwave"]["cycle"] == 57 and d["after_starwave"]["cash_cents"] == contracts[0]["after"]["cash_cents"], f"{cohort}: actual after-Contract state")
        require(d["after_starwave"]["completed_contracts"] == 4, f"{cohort}: fourth distinct completed Contract")
    else:
        require(not contracts and "after_starwave" not in d and "starwave_result" not in d, f"{cohort}: skip leaves offer untouched")
    require(len(d["releases"]) == 1, f"{cohort} {arm}: one actual Game 4 release")
    launch_cycle = 75 if arm == "starwave" else 72
    release = d["releases"][0]
    require(d["game4_launch"]["cycle"] == release["cycle"] == launch_cycle, f"{cohort} {arm}: unpadded Game 4 launch")
    require(release["release_id"] == d["game4_release_id"] and release["genre"] == specialty, f"{cohort} {arm}: matched-Genre Game 4 identity")
    require(d["game4_promotion"] == sum(before["pending_promotion_awards"].values()), f"{cohort} {arm}: existing Neon Promotion consumed at Game 4")
    require(d["game4_release_id"] in d["game4_launch"]["sales"], f"{cohort} {arm}: release is in actual sales portfolio")
    require(d["remaining_starwave_offer"] == (arm == "skip"), f"{cohort} {arm}: Starwave offer state")
    require({int(key) for key in d["endpoints"]} == set(ENDPOINTS), f"{cohort} {arm}: exact three common endpoints")
    checkpoints = {cycle: endpoint(d["endpoints"][str(cycle)], cycle, f"{cohort} {arm} endpoint {cycle}") for cycle in ENDPOINTS}
    for cycle, view in checkpoints.items():
        point = d["endpoints"][str(cycle)]
        in_game5 = point["project_release_id"] != d["game4_release_id"]
        view["project_stage"] = "Game 5" if in_game5 else "after Game 4 launch"
        view["game5_project_cycle"] = point["project_cycle"] if in_game5 else 0
        view["game5_scope"] = point["project_scope"] if in_game5 else 0
    require(d["final"]["cycle"] == 79 and d["final"] == d["endpoints"]["79"], f"{cohort} {arm}: final equals last legal endpoint")
    require(d["game5_hands"] >= 1, f"{cohort} {arm}: actual Game 5 work")
    return d, {"arm": arm, "valid": d["valid"], "stop": d["stop"], "game4": {"cycle": launch_cycle, "review": release["final_review"], "awareness": release["awareness"], "promotion": d["game4_promotion"]},
               "starwave": star, "endpoints": checkpoints}


def compare(cohort: str, star: dict, skip: dict, reported: dict, left: dict, right: dict) -> dict:
    require(star["valid"] and skip["valid"], cohort + ": both arms valid before paired comparison")
    require(star["initial_checkpoint"] == skip["initial_checkpoint"] and star["initial_rng"] == skip["initial_rng"] and star["before"] == skip["before"], cohort + ": identical independently hydrated inputs")
    require(star["game4_release_id"] == skip["game4_release_id"], cohort + ": same Game 4 project identity")
    require(star["game4_promotion"] == skip["game4_promotion"] == sum(star["before"]["pending_promotion_awards"].values()), cohort + ": same existing award consumed")
    rows = []
    for cycle in ENDPOINTS:
        a, b = star["endpoints"][str(cycle)], skip["endpoints"][str(cycle)]
        require(a["cycle"] == b["cycle"] == cycle, cohort + f": matched cycle {cycle}")
        if a["project_release_id"] != star["game4_release_id"] and b["project_release_id"] != skip["game4_release_id"]:
            require(a["project_release_id"] == b["project_release_id"], cohort + f": same Game 5 project {cycle}")
        require(a["released_ids"] == b["released_ids"], cohort + f": same launched portfolio IDs {cycle}")
        # Both arms start from the same exact finance ledger. Each endpoint
        # movement is reconstructed from journal entries after cycle 54.
        base_tx = len(star["before"]["finance"]["transactions"])
        for arm, point in (("starwave", a), ("skip", b)):
            start = star["before"]["cash_cents"]
            newer = point["finance"]["transactions"][base_tx:]
            require(start + sum(tx["cash_delta_cents"] for tx in newer) == point["cash_cents"], cohort + f": {arm} post-input journal at {cycle}")
            require(sum(tx["cash_delta_cents"] for tx in newer if tx["kind"] == "sales_settlement") == point["portfolio_settled_cents"] - star["before"]["portfolio_settled_cents"], cohort + f": {arm} settled sales delta at {cycle}")
        cash_delta = a["cash_cents"] - b["cash_cents"]
        settled_delta = a["portfolio_settled_cents"] - b["portfolio_settled_cents"]
        starwave_receipt = reported["starwave"]["cash_cents"]
        star_new = a["finance"]["transactions"][base_tx:]
        skip_new = b["finance"]["transactions"][base_tx:]
        star_other = sum(tx["cash_delta_cents"] for tx in star_new if tx["kind"] != "sales_settlement" and not (tx["kind"] == "publisher_receipt" and tx["source_id"].endswith(":starwave:first")))
        skip_other = sum(tx["cash_delta_cents"] for tx in skip_new if tx["kind"] != "sales_settlement")
        other_delta = star_other - skip_other
        require(cash_delta == starwave_receipt + settled_delta + other_delta, cohort + f": cash decomposition {cycle}")
        rows.append({"cycle": cycle, "starwave": left["endpoints"][cycle], "skip": right["endpoints"][cycle],
                     "cash_delta_starwave_minus_skip_cents": cash_delta,
                     "starwave_receipt_cents": starwave_receipt,
                     "settled_sales_delta_cents": settled_delta,
                     "other_cash_movement_delta_cents": other_delta,
                     "game5_work_cycle_delta_starwave_minus_skip": left["endpoints"][cycle]["game5_project_cycle"] - right["endpoints"][cycle]["game5_project_cycle"],
                     "game5_scope_delta": left["endpoints"][cycle]["game5_scope"] - right["endpoints"][cycle]["game5_scope"]})
    return {"cohort": cohort, "paired": True, "starwave_game4": left["game4"], "skip_game4": right["game4"], "matched_endpoints": rows}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="New summary path; existing files are never overwritten")
    args = parser.parse_args()
    source = source_gate()
    cards = {card["id"]: card for card in read(source["copy"] / "data/card_ledger.json")}
    results = {}
    pairs = []
    for cohort in COHORTS:
        raw, views = {}, {}
        for arm in ARMS:
            raw[arm], views[arm] = audit_arm(cohort, arm, source, cards)
        results[cohort] = views
        if raw["starwave"]["valid"] and raw["skip"]["valid"]:
            pairs.append(compare(cohort, raw["starwave"], raw["skip"], views["starwave"], views["starwave"], views["skip"]))
        else:
            pairs.append({"cohort": cohort, "paired": False, "reason": "one or both legal arms stopped before all endpoints"})
    summary = {"passed": True, "all_pairs_valid": all(pair["paired"] for pair in pairs), "source_head": source["manifest"]["pinned_head"],
               "source_manifest_sha256": source["manifest_sha256"], "input_hashes": source["manifest"]["inputs"],
               "original_technical_failure": source["original_technical_failure"],
               "v2_adapter_failure": source["v2_adapter_failure"],
               "v3_adapter_failure": source["v3_adapter_failure"], "repaired_revision": source["repair"],
               "attempts": results, "pairs": pairs, "independent_checks": checks,
               "limitations": ["These are three successful v12 foundations under one deterministic policy, not all specialties or player preferences.",
                               "Game 4 review variance is fixed by the inherited verifier hook in both arms; no release result is injected.",
                               "Matched-cycle cash includes a timing/work tradeoff and must be read beside settled sales, bills and Game 5 progress.",
                               "No advance sensitivity or final publisher tuning is approved by this study."]}
    body = json.dumps(summary, indent=2) + "\n"
    if args.output:
        require(not args.output.exists(), "refuse to overwrite an existing audit result")
        args.output.write_text(body, encoding="utf-8")
    print(body, end="")


if __name__ == "__main__":
    main()
