"""Prepare an isolated tracked-source snapshot and analysis-only Store driver."""
from pathlib import Path
import hashlib
import json
import subprocess
import zipfile

OUT = Path(__file__).resolve().parent
REPO = OUT.parents[3]
WORK = Path(r"C:\Users\64jus\Downloads\Patch Notes Design Folder\store-comparison-20261006")
PROJECT = WORK / "patch-notes"
HEAD = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO).decode().strip()
assert not subprocess.check_output(["git", "diff", "--name-only", "--", "patch-notes"], cwd=REPO).strip()
WORK.mkdir(exist_ok=True)
archive = WORK / "source.zip"
if not archive.exists():
    subprocess.run(["git", "archive", "--format=zip", f"--output={archive}", HEAD, "patch-notes"], cwd=REPO, check=True)
    with zipfile.ZipFile(archive) as z:
        z.extractall(WORK)

def sha(data):
    return hashlib.sha256(data).hexdigest()

names = subprocess.check_output(["git", "ls-files", "--", "patch-notes"], cwd=REPO).decode().splitlines()
source = []
for name in names:
    a, b = (REPO/name).read_bytes(), (WORK/name).read_bytes()
    assert a.replace(b"\r\n", b"\n") == b.replace(b"\r\n", b"\n"), name
    source.append({"path": name, "checkout_sha256": sha(a), "archive_sha256": sha(b)})

base = (REPO / "docs/codex/threads/feature-store/sim-v9/driver.gd").read_text(encoding="utf-8-sig")
base = base.replace('extends "res://analysis/task29_routes_v1.gd"', 'extends "res://analysis/task2_analysis/task29_base.gd"')
base = base.replace('var candidate_price_cents := 170000', 'var candidate_price_cents := 170000\nvar candidate_fee := 0\nvar route_key := ""\nvar historical_target: Array = []')
base = base.replace('candidate_price_cents = int(_arg("--price=", "170000"))', 'candidate_price_cents = int(_arg("--price=", "170000"))\n\tcandidate_fee = int(_arg("--fee=", "0"))\n\troute_key = _arg("--key=", "pilot")')
base = base.replace('max_games = 5', 'max_games = 6').replace('action_limit = 150', 'action_limit = 180')
start = base.index('\tvar path := "C:/')
end = base.index('\n\tFileAccess.open(path', start)
base = base[:start] + '\tvar path := _arg("--out=", "user://route.json")' + base[end:]
base = base.replace('"stop": "five releases"', '"stop": "six releases and subsequent earning actions"')
base = base.replace('"candidate_price_cents": candidate_price_cents,', '"candidate_price_cents": candidate_price_cents, "candidate_fee_cents": candidate_fee, "route_key": route_key,')
base = base.replace('\troot.add_child(game)', '\tvar trial = preload("res://analysis/task2_analysis/trial_run_state.gd").new()\n\ttrial.fee_id = &"sub_areas" if store_arm == "sub_areas" else &"background_music"\n\ttrial.fee_cents = candidate_fee\n\tgame.run_state = trial\n\troot.add_child(game)', 1)
base = base.replace('for number in range(1, 6):', 'for number in range(1, 7):').replace('if number == 5: break', 'if number == 6: break')
base = base.replace('\t\t_shop_matched(game, out, number)', '\t\tif number <= 4: _shop_matched(game, out, number)')
base = base.replace('\t_capture_final(game, out)', '\tif out.releases.size() == 6:\n\t\tif _begin_game(game, "Matched Store Follow-through", specialty_id, out):\n\t\t\tawait process_frame\n\t\t\tvar phase: DesignPhase = game.get("_active_phase")\n\t\t\tactive_project = game.project_state\n\t\t\tphase_for_choice = phase\n\t\t\tvar goal: int = game.run_state.get_completed_run_cycles() + 1\n\t\t\tif goal % 2 != 0: goal += 1\n\t\t\twhile game.run_state.get_completed_run_cycles() < goal:\n\t\t\t\tif not _production_hand(phase, game.project_state, game.run_state, era_policy, "mixed", "design", 7, out):\n\t\t\t\t\t_stop(game, out, "follow-through", "earning action rejected"); break\n\t\telse: _stop(game, out, "follow-through", "departure rejected")\n\t_capture_final(game, out)', 1)
base = base.replace('out["captures"] = final_captures', 'out["captures"] = []\n\tout["historical_target"] = historical_target\n\tout["final_finance_snapshot"] = run.get_studio_finance_snapshot()')
base = base[:base.index('func _shop_matched(')]
base += '''func _shop_matched(game: Control, out: Dictionary, number: int) -> void:
    var id := &"sub_areas" if store_arm == "sub_areas" else &"background_music" if store_arm == "background" else &"recorded_sounds" if store_arm == "existing_sound" else &"colored_text" if store_arm == "existing_value" else &""
    if id.is_empty(): return
    var run: RunState = game.run_state
    if run.owns_feature(id): return
    var quote := run.get_feature_store_offer(id)
    var parent_missing: bool = not quote.parent.is_empty() and not run.owns_feature(quote.parent)
    var parent_quote: Dictionary = run.get_primitive_reserve_offer(StringName(quote.parent)) if parent_missing else {}
    var chain_cost: int = int(quote.price_cents) + int(parent_quote.get("price_cents", 0))
    var purchase_cycles := 2 if parent_missing else 1
    var cash: int = run.get_cash_cents()
    var finance: Dictionary = run.get_studio_finance_report()
    var prospective := run.get_owned_feature_ids()
    if parent_missing: prospective.append(StringName(quote.parent))
    prospective.append(id)
    var cards: Array[CardData] = []
    for owned_id: StringName in prospective:
        cards.append(root.get_node("CardDatabase").call("_create_card", run.get("_feature_definitions")[owned_id]))
    var known_play_cents := run.primitive_feature_hand_cost_cents(cards)
    var cycle := run.get_completed_run_cycles()
    var due_count := int((cycle + purchase_cycles + 18) / 2) - int(cycle / 2)
    var rent_reserve := due_count * 50000
    var reserve := rent_reserve + known_play_cents
    var stronger := false
    var settled := 0
    var qualifying_release_id := ""
    if out.releases.size() >= 2:
        var first_review: float = float(out.releases[0].final_review)
        for release: Dictionary in out.releases.slice(1):
            if float(release.final_review) >= 6.0 and float(release.final_review) >= first_review + 1.0:
                stronger = true
                var actual: int = int(run.get_released_game_sales(StringName(release.release_id)).get("settled_cents", 0))
                if actual > settled:
                    settled = actual
                    qualifying_release_id = str(release.release_id)
    var eligible := timing_policy == "immediate" or (timing_policy == "buffer" and cash >= chain_cost + reserve and int(finance.unpaid_rent_cents) == 0) or (timing_policy == "stronger_settled" and stronger and settled > 0)
    out.purchases.append({"id": id, "stage": "timing decision", "game": number, "timing_policy": timing_policy, "quote": quote, "parent_quote": parent_quote, "parent_missing": parent_missing, "chain_cost_cents": chain_cost, "purchase_cycles": purchase_cycles, "reserve_cents": reserve, "rent_reserve_cents": rent_reserve, "known_play_cents": known_play_cents, "prospective_ids": prospective, "native_advice": run.get_feature_spending_advice(id), "cash_cents": cash, "next_due_cycle": finance.next_due_cycle, "unpaid_rent_cents": finance.unpaid_rent_cents, "stronger_review": stronger, "qualifying_release_id": qualifying_release_id, "qualifying_release_settled_cents": settled, "eligible": eligible})
    if not eligible: return
    if parent_missing:
        var parent := StringName(quote.parent)
        var before := _state(game)
        var audit_before := _store_snapshot(game)
        var success := run.purchase_primitive_reserve_feature(parent)
        var action := {"phase": "store", "id": parent, "game": number, "kind": "required Primitive parent", "quote": parent_quote, "success": success, "before": before, "after": _state(game), "rejection_unchanged": success or audit_before == _store_snapshot(game)}
        out.actions.append(action); out.purchases.append(action)
        if not action.rejection_unchanged: discrepancies.append({"kind": "parent rejection mutated"})
        if not success: return
    quote = run.get_feature_store_offer(id)
    var before := _state(game)
    var audit_before := _store_snapshot(game)
    var success := run.purchase_feature(id)
    var action := {"phase": "store", "id": id, "game": number, "kind": "current upgrade" if store_arm.begins_with("existing") else "analysis-only candidate", "quote": quote, "success": success, "before": before, "after": _state(game), "rejection_unchanged": success or audit_before == _store_snapshot(game)}
    out.actions.append(action); out.purchases.append(action)
    if not action.rejection_unchanged: discrepancies.append({"kind": "child rejection mutated"})

func _store_snapshot(game: Control) -> Array:
    return [_state(game), game.run_state.get_owned_feature_ids(), random_inputs.state]

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
    var value: Dictionary = super._state_for(project, run)
    var ledger: Dictionary = run.get("_studio_finance")
    var unpaid := 0
    for bill: Dictionary in ledger.obligations: unpaid += int(bill.unpaid_cents)
    value["unpaid_rent_cents"] = unpaid
    value["credit"] = ledger.credit.score
    return value

func _state(game: Control) -> Dictionary:
    var value: Dictionary = super._state(game)
    var phase: Control = game.get("_active_phase")
    var run: RunState = game.run_state
    if historical_target.is_empty() and phase is AlphaPhase and run.get_completed_run_cycles() == 28 and phase.call("_has_valid_active_candidate_pool") and not phase.is_gameplay_input_blocked():
        historical_target.append({"cycle": 28, "cash_cents": run.get_cash_cents(), "unpaid_rent_cents": run.get_studio_finance_report().unpaid_rent_cents, "free_exit_allowed": phase.call("_can_proceed_to_beta"), "productive_allowed": run.can_complete_productive_cycle()})
    return value
'''.replace('    ', '\t')

trial = '''## Counterfactual fee only; all affordability/transactions remain native.
extends "res://scripts/run_state.gd"
var fee_id := &""
var fee_cents := 0
func primitive_feature_hand_cost_cents(cards: Array[CardData]) -> int:
    var total := super.primitive_feature_hand_cost_cents(cards)
    if total < 0 or not uses_first_studio_economy(): return total
    for card: CardData in cards:
        if card.id == fee_id:
            if fee_cents < 0 or total > MAX_SIGNED_INT - fee_cents: return -1
            total += fee_cents
    return total
'''.replace('    ', '\t')
target = PROJECT / "analysis/task2_analysis"
target.mkdir(exist_ok=True)
native_harness = (PROJECT/"analysis/task29_routes_v1.gd").read_text(encoding="utf-8-sig")
begin = native_harness.index('func _state_for(')
end = native_harness.index('func _capture_final(', begin)
native_harness = native_harness[:begin] + native_harness[end:]
for name, text in [("driver.gd", base), ("trial_run_state.gd", trial), ("task29_base.gd", native_harness)]:
    (OUT/name).write_text(text, encoding="utf-8")
    (target/name).write_text(text, encoding="utf-8")
(OUT/"source-manifest.json").write_text(json.dumps({"head": HEAD, "archive_sha256": sha(archive.read_bytes()), "files": source, "project": str(PROJECT)}, indent=2), encoding="utf-8")
print(json.dumps({"head": HEAD, "project": str(PROJECT), "source_files": len(source), "driver_sha256": sha(base.encode()), "subclass_sha256": sha(trial.encode())}))
