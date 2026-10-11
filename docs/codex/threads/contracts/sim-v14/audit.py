"""Independent audit of the six native Starwave post-Game-5 continuations.

Reads saved traces and the frozen source copy. It never runs Godot or changes a
raw result. --output creates a new summary file and refuses to overwrite one.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
HERE = ROOT / "repair-v3"
V2 = ROOT / "repair-v2"
REPO = ROOT.parents[4]
V12 = ROOT.parent / "sim-v12"
V13 = ROOT.parent / "sim-v13" / "repair-v4"
NATIVE = REPO / "docs/codex/findings/starwave-implementation-v1"
COHORTS = {
    "action-1104": ("action", 1104, "61f1c69c203c9e671e18fc749abac267b368ec3ac91e6b14139affa2db25d335"),
    "puzzle-4417": ("puzzle", 4417, "8c7c42f0edc205eefda55959d7e67f66fd1da0208e4160abf60a4ba972f91381"),
    "racing-1104": ("racing", 1104, "dde276dc491b4d5aff1b395f3db86776fae4839e5b98a28cef5ef3c6ce09559c"),
}
ARMS = ("starwave", "skip")
PREFIX_CYCLES = (75, 77, 79)
LATER_CYCLES = (94, 96, 98)
ALL_CYCLES = PREFIX_CYCLES + LATER_CYCLES
HEAD = "41c87c76fb4d3c06a5332d93f0e7b0997007475d"
checks = 0


def require(condition: bool, label: str) -> None:
    global checks
    checks += 1
    if not condition:
        raise AssertionError(label)


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def clean_drift() -> dict:
    return {"pin_drift": [], "copy_drift": [], "script_drift": [],
            "installed_script_drift": [], "input_drift": [],
            "reference_drift": [], "reference_audit_drift": False,
            "runner_drift": False}


def source_gate() -> dict:
    original_path = NATIVE / "source-manifest-v3.json"
    recovery = read(NATIVE / "source-pin-recovery-v3.json")
    require(recovery["complete"] and recovery["source_manifest_sha256"] == sha(original_path), "complete original native-v3 pin")
    original = read(original_path)
    manifest_path = HERE / "source-manifest.json"
    manifest = read(manifest_path)
    old_manifest = read(V13 / "source-manifest.json")
    failed_manifest_path = ROOT / "source-manifest.json"
    failed_manifest = read(failed_manifest_path)
    failed_parse = read(ROOT / "parse-check" / "command.json")
    require(failed_manifest["files"] == manifest["files"] and failed_manifest["inputs"] == manifest["inputs"], "parse failure used same playable source and typed inputs")
    require(failed_parse["source_manifest_sha256"] == sha(failed_manifest_path) and failed_parse["exit"] == 1 and not failed_parse["timeout"], "preserved initial parse failure source and exit")
    require(any("_beta_hand()" in line and "await" in line for line in failed_parse["errors"]), "initial adapter coroutine error identified")
    require(read(ROOT / "parse-check" / "source-after.json") == clean_drift(), "initial parse failure had no source drift")
    v2_manifest_path = V2 / "source-manifest.json"
    v2_manifest = read(v2_manifest_path)
    require(v2_manifest["files"] == manifest["files"] and v2_manifest["inputs"] == manifest["inputs"], "repair v2 used same playable source and typed inputs")
    v2_folder = V2 / "action-1104-starwave"
    v2_attempt = read(v2_folder / "attempt.json")
    v2_command = read(v2_folder / "command.json")
    v2_trace = read(v2_folder / "post-game5-route.json")
    v2_reference = read(V13 / "action-1104-starwave" / "matched-route.json")
    require(not v2_attempt["native_valid"] and not v2_attempt["driver_failure"] and v2_attempt["stop"] == "v13 cycle-79 replay parity mismatch", "v2 false in-engine parity stop")
    require(v2_command["source_manifest_sha256"] == sha(v2_manifest_path) and v2_attempt["source_after"] == read(v2_folder / "source-after.json") == clean_drift(), "v2 source provenance and no drift")
    require(v2_trace["initial_rng"] == v2_reference["initial_rng"] and v2_trace["before"] == v2_reference["before"], "Python exact v2 initial parity")
    for key in ("game4_launch", "game4_release_id", "game4_promotion", "actions", "releases", "starwave_hands", "starwave_result"):
        require(v2_trace[key] == v2_reference[key], "Python exact v2 prefix parity: " + key)
    for cycle in PREFIX_CYCLES:
        require(v2_trace["endpoints"][str(cycle)] == v2_reference["endpoints"][str(cycle)], f"Python exact v2 endpoint parity {cycle}")
    require(not v2_trace["v13_parity"]["matched"] and v2_trace["endpoints"]["79"] == v2_reference["final"], "v2 in-engine mismatch was a technical comparator failure")
    require(original["head"] == manifest["pinned_head"] == HEAD, "frozen source revision")
    require(manifest["original_manifest_sha256"] == sha(original_path), "original manifest bytes")
    require(manifest["files"] == old_manifest["files"] and manifest["selected_file_count"] == 748, "same selected playable files as v13")
    selected = {name.removeprefix("patch-notes/"): digest
                for name, digest in original["files"].items()
                if name.startswith("patch-notes/") and
                (name.removeprefix("patch-notes/") in {"project.godot", "icon.svg", "icon.svg.import"}
                 or name.removeprefix("patch-notes/").startswith(("scripts/", "analysis/", "assets/", "data/", "resources/", "Scenes/", "scenes/")))}
    require(selected == manifest["files"], "complete source selection")
    pin, copy = Path(manifest["source"]), Path(manifest["analysis_copy"])
    require(pin.resolve() == (Path(recovery["destination"]) / "patch-notes").resolve(), "original pin path")
    for name, digest in selected.items():
        require(sha(pin / name) == digest, "original pin drift: " + name)
        require(sha(copy / name) == digest, "v14 copy drift: " + name)
    for script in ("cross_specialty_base.gd", "post_game5_continuation.gd"):
        require(sha(HERE / script) == manifest["analysis_scripts_sha256"][script], "analysis script hash: " + script)
        require(sha(copy / "scripts/debug" / script) == manifest["analysis_scripts_sha256"][script], "installed script hash: " + script)
    require(sha(HERE / "run.py") == manifest["runner_sha256"], "runner hash")
    require(manifest["inputs"] == {name: data[2] for name, data in COHORTS.items()}, "declared input set")
    for cohort, (_, _, digest) in COHORTS.items():
        require(sha(HERE / "inputs" / f"{cohort}.payload.json") == digest, cohort + ": copied typed input")
        require(sha(V12 / cohort / "before-starwave.payload.json") == digest, cohort + ": original v12 typed input")
        previous = read(V12 / cohort / "attempt.json")
        require(previous["native_valid"] and not previous["driver_failure"], cohort + ": legal v12 foundation")
    old_audit_path = V13 / "audit-summary.json"
    old_audit = read(old_audit_path)
    require(old_audit["passed"] and old_audit["all_pairs_valid"] and sha(old_audit_path) == manifest["v13_audit_sha256"], "verified v13 reference audit")
    require(set(manifest["v13_reference_sha256"]) == {f"{cohort}-{arm}" for cohort in COHORTS for arm in ARMS}, "six v13 reference names")
    for name, digest in manifest["v13_reference_sha256"].items():
        require(sha(V13 / name / "matched-route.json") == digest, "v13 reference trace hash: " + name)
    for gate in ("import", "parse-check"):
        command = read(HERE / gate / "command.json")
        expected_exit = 0 if gate == "import" else 1
        require(command["exit"] == expected_exit and not command["timeout"] and not command["errors"], gate + ": clean Godot process")
        require(command["source_manifest_sha256"] == sha(manifest_path), gate + ": manifest identity")
        require(read(HERE / gate / "source-after.json") == clean_drift(), gate + ": no source or input drift")
    require(read(HERE / "parse-check" / "parse-result.json")["stop"] == "undeclared arm or specialty", "controlled analysis-script parse gate")
    return {"manifest": manifest, "manifest_sha256": sha(manifest_path), "clean": clean_drift(),
            "initial_parse_failure": {"manifest_sha256": sha(failed_manifest_path),
                                      "script_sha256": failed_manifest["analysis_scripts_sha256"],
                                      "godot_exit": failed_parse["exit"], "errors": failed_parse["errors"]},
            "v2_false_parity_failure": {"manifest_sha256": sha(v2_manifest_path),
                                        "stop": v2_attempt["stop"], "v13_prefix_python_exact": True}}


def ledger(finance: dict, label: str) -> None:
    cash = 0
    month_delta = defaultdict(int)
    for sequence, tx in enumerate(finance["transactions"], 1):
        require(tx["sequence"] == sequence, f"{label}: transaction sequence {sequence}")
        require(tx["cash_before_cents"] == cash, f"{label}: transaction opening cash {sequence}")
        cash += tx["cash_delta_cents"]
        require(tx["cash_after_cents"] == cash and cash >= 0, f"{label}: transaction closing cash {sequence}")
        month_delta[tx["month"]] += tx["cash_delta_cents"]
    require(cash == finance["cash_cents"], label + ": finance closing cash")
    opening = 0
    for row in finance["monthly_rows"]:
        month = row["month"]
        require(row["opening_cash_cents"] == opening, f"{label}: month {month} opening")
        require(row["cash_change_cents"] == month_delta[month], f"{label}: month {month} delta")
        require(row["closing_cash_cents"] == opening + month_delta[month], f"{label}: month {month} closing")
        require(row["net_profit_cents"] == row["operating_revenue_cents"] - row["operating_expenses_cents"], f"{label}: month {month} net")
        for kind in ("rent", "payroll"):
            require(row[kind + "_due_cents"] == row[kind + "_paid_cents"] + row[kind + "_unpaid_cents"], f"{label}: month {month} {kind}")
        opening = row["closing_cash_cents"]
    require(opening == cash, label + ": monthly rows reconcile to journal")
    require(sum(item["settled"] for item in finance["actions"]) == sum(row["sales_settled_cents"] for row in finance["monthly_rows"]), label + ": action and monthly sales settlement")
    for bill in finance["obligations"]:
        require(bill["due_cents"] >= 0 and bill["paid_cents"] >= 0 and bill["unpaid_cents"] >= 0, label + ": nonnegative bill")
        require(bill["due_cents"] == bill["paid_cents"] + bill["unpaid_cents"], label + ": original bill amount")
        require(sum(payment["cents"] for payment in bill["payments"]) == bill["paid_cents"], label + ": original bill payments")


def endpoint(point: dict, cycle: int, label: str, game5_id: str = "") -> dict:
    require(point["cycle"] == point["state"]["cycle"] == cycle, label + ": exact completed cycle")
    require(point["cash_cents"] == point["state"]["cash_cents"] == point["finance"]["cash_cents"] == point["finance_report"]["cash_cents"], label + ": cash across captures")
    require(point["finance_valid"] and point["finance"]["last_cycle"] == cycle, label + ": valid finance state at cycle")
    require(point["fans"] == point["fanbase"]["fans"], label + ": Fanbase agrees")
    require(point["released_ids"] == list(point["sales"]), label + ": every released title has sales record")
    require(point["portfolio_settled_cents"] == sum(sale["settled_cents"] for sale in point["sales"].values()), label + ": portfolio settled sum")
    require(point["portfolio_settled_cents"] <= sum(sale["entitlement_cents"] for sale in point["sales"].values()), label + ": settlement no higher than earned entitlement")
    for sale in point["sales"].values():
        require(0 <= sale["settled_cents"] <= sale["entitlement_cents"], label + ": per-title earned and settled sales")
    ledger(point["finance"], label)
    overdue = [{"id": bill["bill_id"], "type": bill["expense_type"], "due_cycle": bill["due_cycle"], "unpaid_cents": bill["unpaid_cents"]}
               for bill in point["finance"]["obligations"] if bill["due_cycle"] <= cycle and bill["unpaid_cents"] > 0]
    game5 = point["sales"].get(game5_id, {}) if game5_id else {}
    if game5:
        require(game5["release_id"] == game5_id and game5["last_settlement_run_cycle"] <= cycle,
                label + ": Game 5 native sale identity and settlement date")
    return {"cycle": cycle, "cash_cents": point["cash_cents"],
            "settled_portfolio_cents": point["portfolio_settled_cents"],
            "earned_portfolio_cents": sum(sale["entitlement_cents"] for sale in point["sales"].values()),
            "game5_settled_cents": game5.get("settled_cents", 0),
            "game5_earned_cents": game5.get("entitlement_cents", 0),
            "game5_earned_cycles": game5.get("total_earned_cycles", 0),
            "game5_last_settlement_cycle": game5.get("last_settlement_run_cycle", -1),
            "game6_work_cycles": point["project_cycle"] if point["project_release_id"] != game5_id else 0,
            "original_overdue_bills": overdue, "credit_score": point["finance_report"]["credit"]["score"],
            "fans": point["fans"], "pending_offers": point["pending_offers"],
            "pending_promotion": point["pending_promotion_awards"]}


def audit_arm(cohort: str, arm: str, source: dict) -> tuple[dict, dict]:
    specialty, seed, digest = COHORTS[cohort]
    name = f"{cohort}-{arm}"
    folder = HERE / name
    previous = read(V13 / name / "matched-route.json")
    previous_attempt = read(V13 / name / "attempt.json")
    require(previous_attempt["native_valid"] and not previous_attempt["driver_failure"] and previous["valid"], name + ": legal v13 reference")
    gate_dir = folder / "replay-gate"
    gate = read(gate_dir / "gate-result.json")
    gate_command = read(gate_dir / "command.json")
    gate_drift = read(gate_dir / "source-after.json")
    gate_parity = read(gate_dir / "parity.json")
    replay = read(gate_dir / "post-79-route.json")
    require(gate["passed"] and gate["godot_exit"] == gate_command["exit"] == 0 and not gate["godot_errors"] and not gate_command["errors"] and not gate_command["timeout"], name + ": separate native stop-at-79 replay passed")
    require(gate["source_after"] == gate_drift == source["clean"], name + ": replay source/input/reference unchanged")
    require(gate["reference_sha256"] == source["manifest"]["v13_reference_sha256"][name] and gate["replay_sha256"] == sha(gate_dir / "post-79-route.json"), name + ": replay/reference hashes")
    require(gate["parity"] == gate_parity and gate_parity["matched"] and all(gate_parity["checks"].values()), name + ": recorded Python replay gate")
    require(gate_command["source_manifest_sha256"] == source["manifest_sha256"] and gate_command["runner_sha256"] == source["manifest"]["runner_sha256"], name + ": replay source/runner identity")
    require(gate_command["analysis_scripts_sha256"] == source["manifest"]["analysis_scripts_sha256"], name + ": replay analysis scripts")
    for arg in ("--stop-at-79=1", f"--specialty={specialty}", f"--seed={seed}", f"--arm={arm}",
                f"--input={HERE / 'inputs' / (cohort + '.payload.json')}",
                f"--reference={V13 / name / 'matched-route.json'}"):
        require(arg in gate_command["command"], name + ": replay command arg " + arg)
    replay_errors = [line for line in (gate_dir / "godot.log").read_text(encoding="utf-8", errors="replace").splitlines()
                     if ("SCRIPT ERROR" in line or line.startswith("ERROR:") or "FAIL:" in line) and "root certificate store" not in line]
    require(not replay_errors and replay["valid"] and not replay["stop"] and replay["ledger_valid"], name + ": replay process clean and valid")
    for key in ("initial_checkpoint", "initial_rng", "before", "game4_launch", "game4_release_id", "game4_promotion", "actions", "releases", "final", "remaining_starwave_offer", "first_blocked_action"):
        require(replay.get(key) == previous.get(key), name + ": independent Python replay parity " + key)
    if arm == "starwave":
        for key in ("after_starwave", "starwave_result", "starwave_hands"):
            require(replay[key] == previous[key], name + ": independent Python replay parity " + key)
    require({int(cycle) for cycle in replay["endpoints"]} == set(PREFIX_CYCLES), name + ": replay stops at exact declared cycle set")
    for cycle in PREFIX_CYCLES:
        require(replay["endpoints"][str(cycle)] == previous["endpoints"][str(cycle)], name + f": independent Python replay endpoint {cycle}")
    attempt, command, drift = (read(folder / item) for item in ("attempt.json", "command.json", "source-after.json"))
    full_parity = read(folder / "parity.json")
    require(attempt["replay_gate_passed"] and attempt["full_prefix_parity"] == full_parity and full_parity["matched"] and all(full_parity["checks"].values()), name + ": recorded full-run prefix parity")
    require(attempt["cohort"] == cohort and attempt["specialty"] == specialty and attempt["seed"] == seed and attempt["arm"] == arm and attempt["input_sha256"] == digest, name + ": declared arm identity")
    require(attempt["source_after"] == drift == source["clean"], name + ": no source/input/reference drift")
    require(not attempt["driver_failure"] and not attempt["godot_errors"] and not command["errors"] and not command["timeout"], name + ": no driver/engine error")
    require(command["exit"] == attempt["godot_exit"] and command["exit"] in (0, 1), name + ": Godot process exit")
    require(command["source_manifest_sha256"] == source["manifest_sha256"] and command["runner_sha256"] == source["manifest"]["runner_sha256"], name + ": source/runner identity")
    require(command["analysis_scripts_sha256"] == source["manifest"]["analysis_scripts_sha256"], name + ": analysis script identity")
    for arg in ("--headless", "--script", f"--specialty={specialty}", f"--seed={seed}", f"--arm={arm}",
                f"--input={HERE / 'inputs' / (cohort + '.payload.json')}",
                f"--reference={V13 / name / 'matched-route.json'}", "--stop-at-79=0"):
        require(arg in command["command"], name + ": native command arg " + arg)
    errors = [line for line in (folder / "godot.log").read_text(encoding="utf-8", errors="replace").splitlines()
              if ("SCRIPT ERROR" in line or line.startswith("ERROR:") or "FAIL:" in line) and "root certificate store" not in line]
    require(not errors, name + ": no hidden engine error")
    trace = read(folder / "post-game5-route.json")
    payload = read(HERE / "inputs" / f"{cohort}.payload.json")
    require(trace["arm"] == arm and trace["specialty"] == specialty and trace["seed"] == seed and trace["input_sha256"] == digest, name + ": native identity")
    require(trace["initial_typed_parity"] and trace["initial_checkpoint"] == payload == previous["initial_checkpoint"], name + ": exact typed hydration")
    require(trace["initial_rng"] == previous["initial_rng"] and trace["before"] == previous["before"], name + ": initial live state/RNG parity")
    require(trace["policy"] == "synergy" and trace["game4_seed"] == seed + 1500000 and trace["game5_seed"] == seed + 2000000, name + ": fixed route policy and seeds")
    require(trace["game4_launch"] == previous["game4_launch"] and trace["game4_release_id"] == previous["game4_release_id"] and trace["game4_promotion"] == previous["game4_promotion"], name + ": exact Game 4 replay")
    for key in ("initial_checkpoint", "initial_rng", "before", "game4_launch", "game4_release_id", "game4_promotion"):
        require(trace[key] == replay[key], name + ": independent full-process and stop-at-79 process parity " + key)
    require(trace["actions"][:len(previous["actions"])] == previous["actions"], name + ": exact native action prefix through cycle 79")
    require(trace["actions"][:len(replay["actions"])] == replay["actions"], name + ": full run matches separate replay-gate actions")
    require(trace["releases"][:len(previous["releases"])] == previous["releases"], name + ": exact released Game 4 prefix")
    if arm == "starwave":
        for field in ("after_starwave", "starwave_result", "starwave_hands"):
            require(trace[field] == previous[field], name + ": exact Starwave " + field)
    else:
        require(all(field not in trace for field in ("after_starwave", "starwave_result", "starwave_hands")), name + ": skip has no Contract result")
    for cycle in PREFIX_CYCLES:
        require(trace["endpoints"][str(cycle)] == previous["endpoints"][str(cycle)], name + f": complete v13 endpoint parity {cycle}")
        require(trace["endpoints"][str(cycle)] == replay["endpoints"][str(cycle)], name + f": separate replay/full process exact endpoint {cycle}")
    require(trace["endpoints"]["79"] == previous["final"], name + ": replay starts from exact v13 final state")
    require(trace["valid"] == attempt["native_valid"] and trace["stop"] == attempt["stop"] and (command["exit"] == 0) == trace["valid"], name + ": native/driver outcome parity")
    if not trace["valid"]:
        return trace, {"arm": arm, "valid": False, "stop": trace["stop"], "last_cycle": trace.get("final", {}).get("cycle")}
    require(not trace["errors"] and not trace["blockers"] and trace["ledger_valid"], name + ": valid native continuation")
    require({int(cycle) for cycle in trace["endpoints"]} == set(ALL_CYCLES), name + ": exact six checkpoints")
    require(len(trace["releases"]) == 2, name + ": actual Games 4 and 5 launches")
    game5 = trace["releases"][1]
    game5_id = trace["game5_release_id"]
    expected_launch = 94 if arm == "starwave" else 91
    require(game5["release_id"] == game5_id and game5["cycle"] == expected_launch, name + ": actual Game 5 release and cycle")
    require(trace["game5_launch"]["cycle"] == expected_launch and game5_id in trace["game5_launch"]["sales"], name + ": Game 5 frozen launch snapshot")
    require(game5["genre"] == specialty and trace["game5_promotion"] == 0, name + ": matched Genre and no new Promotion")
    require([action.get("phase") for action in trace["actions"] if action.get("game") == 5].count("launch") == 1, name + ": one native Game 5 launch action")
    phase_counts = {phase: sum(action.get("phase") == phase and action.get("game") == 5 for action in trace["actions"])
                    for phase in ("design", "alpha", "beta")}
    require(phase_counts == {"design": 6, "alpha": 6, "beta": 6} == trace["game5_phase_counts"], name + ": exact declared Game 5 work")
    allowed = {"contract", "predevelopment", "design", "alpha", "beta", "launch", "design_priority"}
    require(all(action.get("phase") in allowed and action.get("success", True) and not action.get("stop") for action in trace["actions"]), name + ": only planned successful actions")
    require(trace["remaining_starwave_offer"] == (arm == "skip"), name + ": original Starwave offer identity")
    views = {cycle: endpoint(trace["endpoints"][str(cycle)], cycle, f"{name} cycle {cycle}", game5_id) for cycle in ALL_CYCLES}
    require(trace["final"] == trace["endpoints"]["98"] and trace["final"]["cycle"] == 98, name + ": exact final endpoint")
    require(views[94]["game5_settled_cents"] <= views[96]["game5_settled_cents"] <= views[98]["game5_settled_cents"], name + ": nondecreasing actual Game 5 settlement")
    for cycle in LATER_CYCLES:
        require(game5_id in trace["endpoints"][str(cycle)]["sales"], name + f": Game 5 sale remains live at {cycle}")
    require(trace["game6_hands"] >= 1, name + ": legal Game 6 productive work")
    return trace, {"arm": arm, "valid": True, "game5": {"cycle": expected_launch, "review": game5["final_review"],
            "awareness": game5["awareness"], "promotion": trace["game5_promotion"],
            "month_1_units": game5["month_1_units"]}, "endpoints": views}


def compare(cohort: str, raw: dict, views: dict) -> dict:
    star, skip = raw["starwave"], raw["skip"]
    left, right = views["starwave"], views["skip"]
    if not left["valid"] or not right["valid"]:
        return {"cohort": cohort, "paired": False, "reason": "one or both arms stopped before all endpoints"}
    require(star["initial_checkpoint"] == skip["initial_checkpoint"] and star["initial_rng"] == skip["initial_rng"] and star["before"] == skip["before"], cohort + ": paired initial state")
    require(star["game4_release_id"] == skip["game4_release_id"] and star["game5_release_id"] == skip["game5_release_id"], cohort + ": matching project identities")
    require(star["remaining_starwave_offer"] is False and skip["remaining_starwave_offer"] is True, cohort + ": offer choice preserved")
    base = star["before"]
    base_transactions = len(base["finance"]["transactions"])
    payout = star["starwave_result"]["cash"]
    results = []
    for cycle in LATER_CYCLES:
        a, b = star["endpoints"][str(cycle)], skip["endpoints"][str(cycle)]
        require(a["cycle"] == b["cycle"] == cycle, cohort + f": common cycle {cycle}")
        for arm, point in (("starwave", a), ("skip", b)):
            newer = point["finance"]["transactions"][base_transactions:]
            require(base["cash_cents"] + sum(tx["cash_delta_cents"] for tx in newer) == point["cash_cents"], cohort + f": {arm} cash journal to {cycle}")
            require(sum(tx["cash_delta_cents"] for tx in newer if tx["kind"] == "sales_settlement") == point["portfolio_settled_cents"] - base["portfolio_settled_cents"], cohort + f": {arm} actual sales settlement to {cycle}")
        star_new = a["finance"]["transactions"][base_transactions:]
        skip_new = b["finance"]["transactions"][base_transactions:]
        receipt = [tx for tx in star_new if tx["kind"] == "publisher_receipt" and tx["source_id"].endswith(":starwave:first")]
        require(len(receipt) == 1 and receipt[0]["cash_delta_cents"] == payout, cohort + f": exactly one Starwave third-hand receipt by {cycle}")
        require(not any(tx["kind"] == "publisher_receipt" and tx["source_id"].endswith(":starwave:first") for tx in skip_new), cohort + f": no skipped Starwave receipt by {cycle}")
        settled_delta = a["portfolio_settled_cents"] - b["portfolio_settled_cents"]
        other_a = sum(tx["cash_delta_cents"] for tx in star_new if tx["kind"] != "sales_settlement" and tx not in receipt)
        other_b = sum(tx["cash_delta_cents"] for tx in skip_new if tx["kind"] != "sales_settlement")
        cash_delta = a["cash_cents"] - b["cash_cents"]
        require(cash_delta == payout + settled_delta + other_a - other_b, cohort + f": direct receipt + sales + other cash decomposition at {cycle}")
        results.append({"cycle": cycle, "starwave": left["endpoints"][cycle], "skip": right["endpoints"][cycle],
                        "cash_delta_starwave_minus_skip_cents": cash_delta,
                        "starwave_receipt_cents": payout,
                        "settled_portfolio_delta_cents": settled_delta,
                        "settled_game5_delta_cents": left["endpoints"][cycle]["game5_settled_cents"] - right["endpoints"][cycle]["game5_settled_cents"],
                        "other_cash_movement_delta_cents": other_a - other_b,
                        "game6_work_delta": left["endpoints"][cycle]["game6_work_cycles"] - right["endpoints"][cycle]["game6_work_cycles"]})
    return {"cohort": cohort, "paired": True, "game5_starwave": left["game5"],
            "game5_skip": right["game5"], "matched_endpoints": results,
            "starwave_actual_settlement_increments_cents": [results[1]["starwave"]["game5_settled_cents"] - results[0]["starwave"]["game5_settled_cents"],
                                                   results[2]["starwave"]["game5_settled_cents"] - results[1]["starwave"]["game5_settled_cents"]],
            "starwave_settlement_confirmed_at_96_98": [results[1]["starwave"]["game5_last_settlement_cycle"] == 96 and results[1]["starwave"]["game5_settled_cents"] > results[0]["starwave"]["game5_settled_cents"],
                                                      results[2]["starwave"]["game5_last_settlement_cycle"] == 98 and results[2]["starwave"]["game5_settled_cents"] > results[1]["starwave"]["game5_settled_cents"]]}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.output and args.output.exists():
        raise SystemExit("Output exists; refusing to overwrite")
    source = source_gate()
    raw, views = {}, {}
    for cohort in COHORTS:
        raw[cohort], views[cohort] = {}, {}
        for arm in ARMS:
            raw[cohort][arm], views[cohort][arm] = audit_arm(cohort, arm, source)
    pairs = [compare(cohort, raw[cohort], views[cohort]) for cohort in COHORTS]
    summary = {"passed": True, "all_pairs_valid": all(item["paired"] for item in pairs),
               "audit_script_sha256": sha(Path(__file__)),
               "source_head": source["manifest"]["pinned_head"],
               "source_manifest_sha256": source["manifest_sha256"],
               "v13_reference_sha256": source["manifest"]["v13_reference_sha256"],
               "initial_parse_failure": source["initial_parse_failure"],
               "v2_false_parity_failure": source["v2_false_parity_failure"],
               "checks": checks, "attempts": views, "pairs": pairs,
               "limitations": ["Three solvent specialty cohorts and one fixed six-Design continuation policy.",
                               "The pre-Education source pin does not describe moving current-main balance.",
                               "Common-cycle cash includes different Game 6 work progress and is not a final balance lock."]}
    encoded = json.dumps(summary, indent=2)
    if args.output:
        args.output.write_text(encoded + "\n", encoding="utf-8")
    else:
        print(encoded)


if __name__ == "__main__":
    main()
