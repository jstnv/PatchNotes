extends SceneTree
## Isolated candidate: compare the current canonical calculator against both
## checked public and proven-input-only private candidate transitions.
const Before := preload("res://scripts/debug/fixtures/sales_before_trusted_replay.gd")
const Candidate := preload("res://scripts/sales/released_game_sales.gd")
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const Market := preload("res://scripts/market/market_transaction_trial.gd")
var candidate_script: Script = Candidate
var checks := 0
var failures: Array[String] = []
func expect(ok: bool, label: String) -> void:
 checks += 1
 if not ok: failures.append(label); push_error(label)
func clear_candidate() -> void:
 Candidate._validated_records.clear(); Candidate._validated_lookup.clear(); Candidate._validated_record_bytes = 0
 Candidate._factor_history_proofs.clear(); Candidate._factor_history_order.clear(); Candidate._factor_history_bytes = 0
func _initialize() -> void: go.call_deferred()
func go() -> void:
 if not candidate_script.has_method("_next_cycle_validated_replay"):
  print("FAIL: checked sales script lacks the private replay helper")
  quit(1); return
 for item in 24:
  var cal: Dictionary = Clock.fresh() if item % 3 == 0 else (Clock.upgrade({},7) if item % 3 == 1 else {})
  var review: int = (item * 13) % 101
  var awareness: int = 20 + item * 5
  var record := Before.create(StringName("trusted-differential-" + str(item)), 500 + item * 51, review, awareness, 7000 + item * 100, 0, cal, cal)
  for cycle in range(1,81):
   var before := var_to_bytes(record)
   var factor := Market.neutral_factor()
   var start := Clock.month_start(cycle,cal)
   if cycle % 9 == 0 or int(Clock.position(cycle-1,cal).quarter) == 0:
    factor.snapshot_id = ("market-book-v2-%d-" if not cal.is_empty() else "market-book-v1-%d-") % start + "0".repeat(64)
    factor.cycle_start = start
   var campaign: bool = Before.can_campaign(record) and (cycle + item) % 7 == 0
   var expected := Before.next_cycle(record,cycle,Clock.is_boundary(cycle,cal),campaign,10000,factor.snapshot_id,factor)
   var public := Candidate.next_cycle(record,cycle,Clock.is_boundary(cycle,cal),campaign,10000,factor.snapshot_id,factor)
   var trusted: Dictionary = candidate_script.call("_next_cycle_validated_replay",record,cycle,Clock.is_boundary(cycle,cal),campaign,10000,factor.snapshot_id,factor,false)
   expect(not expected.is_empty() and var_to_bytes(public) == var_to_bytes(expected), "public parity %d/%d" % [item,cycle])
   expect(var_to_bytes(trusted) == var_to_bytes(expected), "trusted parity %d/%d" % [item,cycle])
   expect(var_to_bytes(record) == before, "unchanged input %d/%d" % [item,cycle])
   if not trusted.is_empty(): expect(Before._validate_record(trusted), "independent output validation %d/%d" % [item,cycle])
   if expected.is_empty(): break
   record = expected
  if not record.is_empty():
   var corrupt := record.duplicate(true)
   corrupt.entitlement_cents += 1
   expect(Before.next_cycle(corrupt,81,Clock.is_boundary(81,cal)).is_empty() and Candidate.next_cycle(corrupt,81,Clock.is_boundary(81,cal)).is_empty(), "public path rejects forged input")
   var gap_before := Before.next_cycle(record,83,Clock.is_boundary(83,cal))
   var gap_trusted: Dictionary = candidate_script.call("_next_cycle_validated_replay",record,83,Clock.is_boundary(83,cal),false,10000,"market-0-neutral",{},false)
   expect(var_to_bytes(gap_before) == var_to_bytes(gap_trusted), "nonsequential fallback parity")
 # Revalidate a small subset with no candidate proof caches before every call.
 for cal in [Clock.fresh(),Clock.upgrade({},7),{}]:
  var record := Before.create(&"cold-proof",800,70,100,10000,0,cal,cal)
  for cycle in range(1,13):
   var expected := Before.next_cycle(record,cycle,Clock.is_boundary(cycle,cal))
   clear_candidate()
   var trusted: Dictionary = candidate_script.call("_next_cycle_validated_replay",record,cycle,Clock.is_boundary(cycle,cal),false,10000,"market-0-neutral",{},false)
   expect(not trusted.is_empty() and var_to_bytes(trusted) == var_to_bytes(expected) and Candidate._validate_record(trusted), "cold candidate parity %d" % cycle)
   if expected.is_empty(): break
   record = expected
  clear_candidate()
  expect(candidate_script.call("_next_cycle_validated_replay",record,-1,false,false,10000,"market-0-neutral",{},false).is_empty(), "negative run cycle rejected")
  expect(candidate_script.call("_next_cycle_validated_replay",record,13,false,false,6999,"market-0-neutral",{},false).is_empty(), "out-of-range factor rejected")
  expect(candidate_script.call("_next_cycle_validated_replay",record,13,false,false,10000,"",{},false).is_empty(), "empty snapshot rejected")
 var modern: Dictionary = Clock.fresh()
 var proven := Before.create(&"proof-publication",800,70,100,10000,0,modern,modern)
 for cycle in range(1,7): proven = Before.next_cycle(proven,cycle,Clock.is_boundary(cycle,modern))
 clear_candidate()
 var public_result := Candidate.next_cycle(proven,7,Clock.is_boundary(7,modern))
 expect(not public_result.is_empty() and Candidate._validated_lookup.has(var_to_bytes(public_result)), "public valid transition still publishes exact proof")
 clear_candidate()
 var private_result: Dictionary = candidate_script.call("_next_cycle_validated_replay",proven,7,Clock.is_boundary(7,modern),false,10000,"market-0-neutral",{},false)
 expect(private_result == public_result and not Candidate._validated_lookup.has(var_to_bytes(private_result)), "private replay avoids publishing ephemeral proof")
 expect(Before.create(&"overflow-total",ProjectState.MAX_SIGNED_INT).is_empty() and Candidate.create(&"overflow-total",ProjectState.MAX_SIGNED_INT).is_empty(), "overflowing initial revenue is rejected by both checked constructors")
 expect(Before.create(&"overflow-awareness",751,70,ProjectState.MAX_SIGNED_INT,10000).is_empty() and Candidate.create(&"overflow-awareness",751,70,ProjectState.MAX_SIGNED_INT,10000).is_empty(), "overflowing awareness is rejected by both checked constructors")
 var max_cycle_before := Before.next_cycle(proven,ProjectState.MAX_SIGNED_INT,false)
 var max_cycle_after: Dictionary = candidate_script.call("_next_cycle_validated_replay",proven,ProjectState.MAX_SIGNED_INT,false,false,10000,"market-0-neutral",{},false)
 expect(var_to_bytes(max_cycle_before)==var_to_bytes(max_cycle_after), "maximum run-cycle and overflow safeguards remain identical")
 var chronological := Before.create(&"chronology",500,70,20,10000,0,modern,modern)
 for cycle in range(1,9): chronological = Before.next_cycle(chronological,cycle,Clock.is_boundary(cycle,modern))
 var wrong_factor := Market.neutral_factor(); wrong_factor.snapshot_id="market-v3-4-"+"0".repeat(64); wrong_factor.cycle_start=4
 expect(Market.valid_factor(wrong_factor), "misdated factor is structurally valid")
 var wrong_before := Before.next_cycle(chronological,9,false,false,10000,wrong_factor.snapshot_id,wrong_factor)
 var wrong_trusted: Dictionary = candidate_script.call("_next_cycle_validated_replay",chronological,9,false,false,10000,wrong_factor.snapshot_id,wrong_factor,false)
 expect(wrong_before.is_empty() and wrong_trusted.is_empty(), "misdated market provenance is rejected by checked fallback")
 print("SALES_TRUSTED_REPLAY checks=",checks," failures=",failures.size())
 quit(0 if failures.is_empty() else 1)
