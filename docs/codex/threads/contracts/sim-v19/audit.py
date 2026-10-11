"""Independent saved-output audit of the bounded matched economic continuation."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
CONTRACTS = HERE.parent
REPO = HERE.parents[4]
EVIDENCE = REPO / "docs/codex/findings/starwave-implementation-v1"
SPECIALTIES = ("adventure", "role_playing", "strategy", "simulation")
ARMS = ("buy_chain", "no_buy")
ENDPOINTS = (93, 95, 97)
HEX_ID = re.compile(r"\b[0-9a-f]{32}\b")
checks = 0

spec = importlib.util.spec_from_file_location("v18_independent_checks", CONTRACTS / "sim-v18/audit.py")
core = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(core)


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
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize(value):
    """Ignore only fresh-run identity and its isolated snapshot RNG stream."""
    if isinstance(value, str):
        return HEX_ID.sub("<run>", value)
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, dict):
        return {normalize(key): ("<run-seeded>" if key == "snapshot" else normalize(item))
                for key, item in value.items()}
    return value


def source_gate() -> dict:
    local_path = HERE / "source-manifest.json"
    local = read(local_path)
    original_path = EVIDENCE / "source-manifest-v3.json"
    recovery = read(EVIDENCE / "source-pin-recovery-v3.json")
    require(recovery["complete"] and sha(original_path) == recovery["source_manifest_sha256"], "original source/recovery")
    require(sha(original_path) == local["original_manifest_sha256"], "native-v3 source pin")
    original = read(original_path)
    require(original["head"] == local["pinned_head"] == "41c87c76fb4d3c06a5332d93f0e7b0997007475d", "declared HEAD")
    selected = {
        name.removeprefix("patch-notes/"): digest for name, digest in original["files"].items()
        if name.startswith("patch-notes/") and (
            name.removeprefix("patch-notes/") in {"project.godot", "icon.svg", "icon.svg.import"}
            or name.removeprefix("patch-notes/").startswith(("scripts/", "analysis/", "assets/", "data/", "resources/", "Scenes/", "scenes/"))
        )
    }
    require(selected == local["files"] and len(selected) == local["selected_file_count"] == 748, "selected files")
    pin, copy = Path(local["source"]), Path(local["analysis_copy"])
    require(pin.resolve() == Path(recovery["destination"]).resolve() / "patch-notes", "full recovered pin")
    for name, expected in selected.items():
        require(sha(pin / name) == expected, "pin drift: " + name)
        require(sha(copy / name) == expected, "copy drift: " + name)
    for key, path in (("analysis_route_sha256", HERE / "matched_economics_route.gd"),
                      ("analysis_base_sha256", HERE / "starter_buy_base.gd"),
                      ("runner_sha256", HERE / "run.py"),
                      ("installed_route_sha256", copy / "scripts/debug/matched_economics_route.gd"),
                      ("installed_base_sha256", copy / "scripts/debug/starter_buy_base.gd")):
        require(sha(path) == local[key], "analysis driver hash: " + key)
    imported = read(HERE / "import/command.json")
    require(imported["exit"] == 0 and not imported["errors"] and not imported["timeout"], "native import")
    require(imported["source_manifest_sha256"] == sha(local_path), "import source hash")
    require(all(not value for value in read(HERE / "import/source-after.json").values()), "import source drift")
    return {"local": local, "manifest_sha256": sha(local_path), "copy": copy}


def purchase_audit(d: dict, cards: dict, label: str) -> None:
    require(d["initial"]["cash_cents"] == d["before_purchase_cash_cents"] == 565000, label + ": genuine startup")
    require(set(d["before_purchase_owned_ids"]) == set(d["initial_owned_ids"]) - {p["id"] for p in d["purchases"]}, label + ": ownership delta")
    if d["arm"] == "no_buy":
        require(not d["purchases"] and d["spent_cents"] == 0, label + ": no-buy arm")
        return
    spent = 0
    scope = sum(cards[card_id]["scope"] for card_id in d["before_purchase_owned_ids"])
    expected = []
    for offer in d["starter_offers"]:
        if scope >= 33:
            break
        if spent + offer["price_cents"] > 150000:
            continue
        expected.append(offer["id"])
        spent += offer["price_cents"]
        scope += offer["scope"]
    require([p["id"] for p in d["purchases"]] == expected, label + ": exact shopping policy")
    require(d["spent_cents"] == spent == 135000, label + ": exact starter spend")
    for purchase in d["purchases"]:
        quote = purchase["quote"]
        require(purchase["success"] and not quote["owned"] and quote["id"] == purchase["id"], label + ": live available offer")
        require(quote["price_cents"] == (quote["scope"] + 1) * 15000, label + ": primitive price")
        require(purchase["cash_before"] - purchase["cash_after"] == quote["price_cents"], label + ": exact cash charge")
        require(purchase["cycle_before"] == purchase["cycle_after"] == 0, label + ": zero-cycle starter")
        require(set(purchase["owned_after"]) == set(purchase["owned_before"]) | {purchase["id"]}, label + ": owned once")


def prefix_audit(d: dict, specialty: str, arm: str) -> None:
    reference_dir = CONTRACTS / ("sim-v18" if arm == "buy_chain" else "sim-v12") / f"{specialty}-1104"
    reference = read(reference_dir / "native-route.json")
    require(read(reference_dir / "attempt.json")["driver_failure"] is False, specialty + arm + ": clean reference")
    for key, old_key in (("actions", "actions"), ("releases", "releases"), ("cycles", "cycles"),
                         ("state", "final"), ("finance", "finance")):
        require(normalize(d["prefix"][key]) == normalize(reference[old_key]),
                specialty + arm + ": exact normalized foundation " + key)
    require(d["prefix"]["state"]["cycle"] == (57 if arm == "buy_chain" else 32), specialty + arm + ": prefix cycle")


def debt(endpoint: dict) -> int:
    return sum(max(0, loan["schedule"]["principal_cents"] - loan["principal_paid_cents"])
               for loan in endpoint["finance"]["bank_loans"])


def unpaid(endpoint: dict) -> int:
    return sum(bill["unpaid_cents"] for bill in endpoint["finance"]["obligations"])


def audit_attempt(folder: Path, source: dict, cards: dict) -> dict:
    specialty, arm = folder.name.rsplit("-", 1)
    # The buy arm's folder uses a two-part suffix.
    if folder.name.endswith("-buy_chain"):
        specialty = folder.name.removesuffix("-buy_chain")
        arm = "buy_chain"
    require(specialty in SPECIALTIES and arm in ARMS, folder.name + ": declared cohort")
    meta, command, drift = (read(folder / name) for name in ("attempt.json", "command.json", "source-after.json"))
    require(all(not value for value in drift.values()) and meta["source_after"] == drift, folder.name + ": source drift")
    require(not meta["driver_failure"] and not meta["godot_errors"] and not command["errors"] and not command["timeout"], folder.name + ": driver")
    require(command["source_manifest_sha256"] == source["manifest_sha256"], folder.name + ": source hash")
    for key in ("route", "base", "runner"):
        require(command[f"{key}_sha256"] == source["local"][f"analysis_{key}_sha256" if key != "runner" else "runner_sha256"], folder.name + ": driver " + key)
    require(command["exit"] == meta["godot_exit"] == 0, folder.name + ": process exit")
    require(f"--specialty={specialty}" in command["command"] and f"--arm={arm}" in command["command"] and "--seed=1104" in command["command"], folder.name + ": exact inputs")
    log_errors = [line for line in (folder / "godot.log").read_text(encoding="utf-8", errors="replace").splitlines()
                  if ("SCRIPT ERROR" in line or line.startswith("ERROR:") or "FAIL:" in line) and "root certificate store" not in line]
    require(not log_errors, folder.name + ": hidden Godot errors")
    d = read(folder / "native-route.json")
    require(d["valid"] and not d["stop"] and not d["errors"] and not d["blockers"] and d["ledger_valid"], folder.name + ": native success")
    require(d["source"] == "native-v3" and d["seed"] == 1104 and d["specialty"] == d["project_genre"] == specialty and d["arm"] == arm, folder.name + ": native identity")
    require(d["policy"] == "synergy" and d["contract_deal_seed"] == 31104 and d["traits"] == ["lean_production", "studio_buzz", "expensive_lease"], folder.name + ": fixed choices")
    purchase_audit(d, cards, folder.name)
    prefix_audit(d, specialty, arm)
    require([state["cycle"] for state in d["cycles"]] == list(range(1, 98)), folder.name + ": every cycle once")
    core.check_state(d["initial"], folder.name + " initial")
    for state in d["cycles"]:
        core.check_state(state, folder.name + f" cycle {state['cycle']}")
    core.check_state(d["final"]["state"], folder.name + " final")
    releases = d["releases"]
    expected_cycles = [12, 32, 52, 75, 93] if arm == "buy_chain" else [12, 32, 50, 68, 86]
    require(len(releases) == 5 and [release["cycle"] for release in releases] == expected_cycles, folder.name + ": five native release cycles")
    require(len({release["release_id"] for release in releases}) == 5, folder.name + ": distinct releases")
    require(all(release["genre"] == specialty for release in releases), folder.name + ": matching genre")
    for game in range(1, 6):
        counts = [sum(a.get("phase") == phase and a.get("game") == game for a in d["actions"]) for phase in ("design", "alpha", "beta")]
        require(counts == ([3, 4, 4] if game == 1 else [5, 6, 6]), folder.name + f": Game {game} fixed legal hands")
        launches = [a for a in d["actions"] if a.get("phase") == "launch" and a.get("game") == game]
        require(len(launches) == 1 and launches[0]["success"] and not launches[0]["budget_curtailed"], folder.name + f": Game {game} launch")
    design6 = sum(a.get("phase") == "design" and a.get("game") == 6 for a in d["actions"])
    alpha6 = sum(a.get("phase") == "alpha" and a.get("game") == 6 for a in d["actions"])
    require((design6, alpha6) == ((3, 0) if arm == "buy_chain" else (6, 4)), folder.name + ": Game 6 progress")
    require(d["game6_design_hands"] == design6 and d["game6_alpha_hands"] == alpha6, folder.name + ": progress count")
    contracts = [a for a in d["actions"] if a.get("phase") == "contract" and "result" in a]
    expected_publishers = ["ironclad", "crown_quill", "neon_circuit", "starwave"] if arm == "buy_chain" else ["ironclad"]
    require([core.publisher(a["offer_id"]) for a in contracts] == expected_publishers, folder.name + ": real chosen publisher chain")
    require(len({a["offer_id"] for a in contracts}) == len(contracts), folder.name + ": unique completed offers")
    for index, contract in enumerate(contracts, 1):
        core.card_audit(contract, cards, f"{folder.name} contract {index}")
    require(d["foundation_contract_count"] == (3 if arm == "buy_chain" else 1), folder.name + ": pre-Starwave contracts")
    require(d["offer_earned"] == (arm == "buy_chain") and d["starwave_completed"] == (arm == "buy_chain"), folder.name + ": genuine offer outcome")
    require(d["late_loan_accepted"] == (arm == "buy_chain"), folder.name + ": declared real Bank outcome")
    require(set(d["endpoints"]) == {str(cycle) for cycle in ENDPOINTS}, folder.name + ": all matched cycles")
    for cycle in ENDPOINTS:
        endpoint = d["endpoints"][str(cycle)]
        require(endpoint["cycle"] == cycle and endpoint["finance_valid"], folder.name + f": endpoint {cycle}")
        core.check_state(endpoint["state"], folder.name + f" endpoint {cycle}")
        require(endpoint["cash_cents"] == endpoint["finance"]["cash_cents"], folder.name + f": endpoint cash {cycle}")
        require(endpoint["portfolio_settled_cents"] == sum(sale["settled_cents"] for sale in endpoint["sales"].values()), folder.name + f": settled portfolio {cycle}")
        require(endpoint["portfolio_entitlement_cents"] == sum(sale["entitlement_cents"] for sale in endpoint["sales"].values()), folder.name + f": earned portfolio {cycle}")
        transactions = endpoint["finance"]["transactions"]
        require(endpoint["portfolio_settled_cents"] == sum(t["cash_delta_cents"] for t in transactions if t["kind"] == "sales_settlement"), folder.name + f": settled sales cash journal {cycle}")
        require(endpoint["portfolio_entitlement_cents"] == sum(t["amount_cents"] for t in transactions if t["kind"] == "sales_earned"), folder.name + f": earned sales journal {cycle}")
        require(set(endpoint["released_ids"]) == set(endpoint["sales"]), folder.name + f": every released title has sales {cycle}")
        require(endpoint["completed_contracts"] == len(contracts), folder.name + f": committed contracts at {cycle}")
    game5_id = releases[4]["release_id"]
    game5_sales = [d["endpoints"][str(cycle)]["sales"][game5_id]["settled_cents"] for cycle in ENDPOINTS]
    require(game5_sales[0] <= game5_sales[1] <= game5_sales[2], folder.name + ": cumulative Game-5 settlement")
    if arm == "buy_chain":
        require(game5_sales[0] == 0 and game5_sales[1] > 0 and game5_sales[2] > game5_sales[1], folder.name + ": two post-launch buy settlements")
    else:
        require(game5_sales[0] > 0, folder.name + ": earlier Game-5 launch settled before cycle 93")
    endpoints = {}
    for cycle in ENDPOINTS:
        e = d["endpoints"][str(cycle)]
        endpoints[str(cycle)] = {
            "cash_cents": e["cash_cents"],
            "bank_principal_outstanding_cents": debt(e),
            "original_bills_unpaid_cents": unpaid(e),
            "credit_score": e["finance_report"]["credit"]["score"],
            "portfolio_settled_cents": e["portfolio_settled_cents"],
            "portfolio_entitlement_cents": e["portfolio_entitlement_cents"],
            "game5_settled_cents": e["sales"][game5_id]["settled_cents"],
            "game6_work_cycles": cycle - expected_cycles[4],
            "game6_design_hands": sum(a.get("game") == 6 and a.get("phase") == "design" and a["after"]["cycle"] <= cycle for a in d["actions"]),
            "game6_alpha_hands": sum(a.get("game") == 6 and a.get("phase") == "alpha" and a["after"]["cycle"] <= cycle for a in d["actions"]),
        }
    return {"specialty": specialty, "arm": arm, "foundation_reviews": [r["final_review"] for r in releases[:3]],
            "game4_review": releases[3]["final_review"], "game5_review": releases[4]["final_review"],
            "release_cycles": expected_cycles, "starter_spend_cents": d["spent_cents"],
            "loan_accepted_early": d["loan_accepted"], "loan_accepted_late": d["late_loan_accepted"],
            "game5_release_id": game5_id, "endpoints": endpoints}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise RuntimeError("Refusing to overwrite audit summary")
    source = source_gate()
    cards = {card["id"]: card for card in read(source["copy"] / "data/card_ledger.json")}
    folders = [HERE / f"{specialty}-{arm}" for specialty in SPECIALTIES for arm in ARMS]
    require(all(folder.is_dir() for folder in folders), "exact four paired cohorts present")
    attempts = [audit_attempt(folder, source, cards) for folder in folders]
    pairs = []
    for specialty in SPECIALTIES:
        buy = next(a for a in attempts if a["specialty"] == specialty and a["arm"] == "buy_chain")
        no_buy = next(a for a in attempts if a["specialty"] == specialty and a["arm"] == "no_buy")
        require(buy["release_cycles"][-1] - no_buy["release_cycles"][-1] == 7, specialty + ": seven-cycle later launch")
        delta = {}
        for cycle in ENDPOINTS:
            delta[str(cycle)] = {key: buy["endpoints"][str(cycle)][key] - no_buy["endpoints"][str(cycle)][key]
                                 for key in buy["endpoints"][str(cycle)]}
        pairs.append({"specialty": specialty, "buy_minus_no_buy": delta})
    summary = {"passed": True, "scope": "matched native starter-buy/chain versus no-buy/no-chain to cycle97",
               "source_head": source["local"]["pinned_head"], "source_manifest_sha256": source["manifest_sha256"],
               "original_native_v3_manifest_sha256": source["local"]["original_manifest_sha256"],
               "source_file_count": source["local"]["selected_file_count"], "attempts": attempts,
               "pairs": pairs, "independent_checks": checks + core.checks,
               "prefix_normalization": "per-run 32-hex IDs and identity-seeded snapshot RNG only",
               "limitations": ["One seed and one Store/production policy for four specialties.",
                               "Buy+chain versus no-buy/no-chain is a package comparison, not a causal decomposition.",
                               "The source predates Education activation on current main.",
                               "No gameplay, price, gate, cap, advance or final balance approval follows."]}
    args.output.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({"passed": True, "attempts": len(attempts), "pairs": pairs,
                      "independent_checks": summary["independent_checks"]}, indent=2))


if __name__ == "__main__":
    main()
