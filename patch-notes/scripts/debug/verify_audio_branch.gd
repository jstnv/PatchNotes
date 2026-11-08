extends SceneTree
const Owned=preload("res://scripts/debug/owned_engine_test_setup.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var count := 0
var failures := 0
func check(ok: bool,label: String) -> void:
 count+=1
 if not ok: failures+=1;push_error("FAIL: "+label)
func fresh(genre: StringName = &"sports") -> RunState:
 var s: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"audio-fixture","studio_name":"Audio","specialty":str(genre),"traits":[],"seed":"715"},root.get_node("CardDatabase").get_development_catalog())
 if s==null:return null
 s.run.finalize_starter_selection()
 return s.run
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var args:=OS.get_cmdline_user_args()
 if args.size()==2 and args[0]=="--capture":
  var prior_run:=fresh()
  check(prior_run!=null,"Old sports initializes")
  for id: StringName in [&"8_bit_music"]:
   check(prior_run.admit_feature_research(prior_run.get_feature_research_quote(id)),"Old music admission")
   check(prior_run.research_feature(prior_run.get_feature_research_quote(id)),"Old music completion")
  check(prior_run.admit_feature_research(prior_run.get_feature_research_quote(&"16_bit_music")),"Retired upgrade pending before change")
  var a:=StudioCheckpoint.new()
  var prior_saved:=a.capture(prior_run)
  check(not prior_saved.is_empty() and a.validate(prior_saved).is_empty(),"Real retired pending checkpoint valid")
  FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"player":prior_saved,"source":Replay.source_identity()}))
  quit(failures);return
 var r:=fresh(&"action")
 check(r.add_cash_cents(2000000,&"other_income",&"audio_owned_setup"),"Recorded owned-engine fixture funding")
 check(Owned.create_owned(r,"Audio owned"),"Paid real owned engine and selection")
 check(Owned.acquire(r,&"8_bit_sound"),"Paid root before Audio branches")
 check(r!=null,"New action initializes")
 var graph:=FeatureStoreCatalog.graph(r._feature_definitions,r._feature_offers)
 check(graph.parents[&"8_bit_sound"].is_empty(),"Audio root has no parent")
 for row: Array in [[&"16_bit_sound",&"design",7,0,2,170000,[&"8_bit_sound"]],[&"main_theme",&"alpha",7,0,2,170000,[&"8_bit_sound"]],[&"multiple_soundtracks",&"design",5,2,2,190000,[&"main_theme"]],[&"instrumental_sounds",&"alpha",7,0,2,190000,[&"recorded_sounds"]],[&"dynamic_sequencing",&"design",7,2,3,240000,[&"multiple_soundtracks",&"instrumental_sounds"]]]:
  var e: Dictionary=r._feature_definitions.get(row[0],{})
  check(not e.is_empty(),"New Audio card exists "+str(row[0]))
  if e.is_empty():continue
  check([str(e.phase),int(e.primary_value),int(e.secondary_value),int(e.scope),int(e.base_price_cents)]==[str(row[1]),row[2],row[3],row[4],row[5]],"Approved values/phase "+str(row[0]))
  check(e.play_cost_cents==0 and not e.renewable,"Finite and zero direct play fee")
  check(graph.parents[row[0]]==row[6],"Exact ordered parents "+str(row[0]))
 for genre: StringName in StudioSpecialties.RULES:
  var p:=StudioSpecialties.preview(genre)
  check(p.scope==12 and p.roster_version==5,"Root-connected12 Scope v5 "+str(genre))
  check(p.ids.has(&"8_bit_sound") and not p.ids.has(&"sound_effects") and not p.ids.has(&"music"),"New founder only active Audio "+str(genre))
  for id: StringName in p.ids:
   for parent: StringName in graph.parents[id]:check(p.ids.has(parent),"Founder has parent "+str(id))
 for id: StringName in [&"music",&"sound_effects",&"8_bit_music",&"16_bit_music"]:
  var q:=r.get_feature_research_quote(id)
  check(q.is_empty() or not q.can_admit,"Retired node cannot be newly queued "+str(id))
  check(r._feature_definitions.has(id),"Legacy definition retained "+str(id))
 var store:=FeatureStore.new();root.add_child(store);store.setup(r)
 check(store._nodes.size()==50,"50 active map nodes")
 check(store.LANE_MEMBERS[&"Audio"].size()==7,"Seven Audio nodes")
 for id: StringName in [&"music",&"sound_effects",&"8_bit_music",&"16_bit_music"]:check(not store._nodes.has(id),"Retired node absent from map")
 store._select_node(&"16_bit_sound")
 check(store._details.text.contains("Replaces 8-Bit Sound"),"Upgrade details explain future-supply replacement")
 var frozen:=PrimitivePredevelopment.prepare_project("Before upgrade",&"action",&"fantasy",r)
 check(frozen!=null and frozen.get_feature_supply_ids().has(&"8_bit_sound"),"Begun project has old root supply")
 # Deliberately funded mechanics fixture; no new-game solvency claim.
 check(r.add_cash_cents(2000000,&"other_income",&"audio_test_funding"),"Fixture funding is recorded")
 for id: StringName in [&"16_bit_sound",&"main_theme",&"recorded_sounds",&"multiple_soundtracks",&"instrumental_sounds",&"dynamic_sequencing"]:
  var quote:=r.get_feature_research_quote(id)
  check(quote.can_admit,"Parent-gated legal admission "+str(id))
  check(r.admit_feature_research(quote),"Public admission commits "+str(id))
  check(not r.owns_feature(id),"Down payment grants no ownership")
  check(r.research_feature(r.get_feature_research_quote(id)),"Legal research completes "+str(id))
  check(r.owns_feature(id),"Own exact completed card")
 check(r.owns_feature(&"8_bit_sound") and not r.get_future_project_feature_ids().has(&"8_bit_sound") and r.get_future_project_feature_ids().has(&"16_bit_sound"),"Only future supply replaces root; ownership remains")
 check(frozen.get_feature_supply_ids().has(&"8_bit_sound") and not frozen.get_feature_supply_ids().has(&"16_bit_sound"),"Already-begun supply frozen across upgrade")
 var expected_cards: Array[CardData]=[]
 for id: StringName in r.get_future_project_feature_ids():expected_cards.append(root.get_node("CardDatabase").get_card(id))
 var advice:=r.get_feature_spending_advice()
 check(advice.available and advice.known_play_cost_cents==r.primitive_feature_hand_cost_cents(expected_cards) and advice.owned_feature_count==expected_cards.size(),"Next-project advice excludes replaced root fee/count")
 var next:=PrimitivePredevelopment.prepare_project("After upgrade",&"action",&"fantasy",r)
 check(not next.get_feature_supply_ids().has(&"8_bit_sound") and next.get_feature_supply_ids().has(&"16_bit_sound"),"Ordinary Begin uses upgraded supply")
 var before:=Replay.digest(Replay.freeze(r))
 check(not r.admit_feature_research({"feature_id":&"dynamic_sequencing","can_admit":true}),"Forged admission rejected")
 check(before==Replay.digest(Replay.freeze(r)),"Rejected admission changes no state/RNG")
 var engine_before:=r._engine_features.duplicate(true)
 for missing: StringName in [&"multiple_soundtracks",&"instrumental_sounds"]:
  var held: bool=r._engine_features.engines[r.get_selected_engine_id()].implemented.has(missing)
  r._engine_features.engines[r.get_selected_engine_id()].implemented.erase(missing)
  check(not r.get_feature_store_offer(&"dynamic_sequencing").unlocked,"Every Dynamic Sequencing AND arm required "+str(missing))
  if held:r._engine_features.engines[r.get_selected_engine_id()].implemented.append(missing)
 r._engine_features=engine_before
 var adapter:=StudioCheckpoint.new()
 var saved:=adapter.capture(r)
 check(not saved.is_empty() and adapter.hydrate(saved)!=null,"Current funded ownership/payment/history saves round trip: "+adapter.error)
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://scripts/debug/fixtures/audio_predecessor_20261028.json"))
 var legacy:=adapter.hydrate(old.player)
 check(legacy!=null,"Exact prior retired queue restores")
 if legacy!=null:
  var expected: Dictionary=old.player.duplicate(true);expected.content_revision=adapter.revision()
  var migrated:=adapter.capture(legacy)
  var historical:=migrated.duplicate(true)
  # Source-pinned approved additions only; every historical field and full RNG remains exact.
  historical.source_build=expected.source_build
  for key in ["calendar_start_year","rival_founder_profile","historical_close_cycle","closed_historical_ids","engine_entitlements","release_engine_ids","engine_royalty_receipts","engine_features","calendar"]:historical.run.erase(key)
  historical.run.studio_finance.erase("calendar")
  historical.run.studio_finance.erase("calendar_cutover_actions")
  historical.run.fanbase.erase("calendar")
  check(historical==expected,"Every pre-existing ownership/payment/finance/RNG field retained after explicit additive migration projection")
  check(adapter.capture(adapter.hydrate(migrated))==migrated,"Full migrated current save is cold-idempotent")
  var quote:=legacy.get_feature_research_quote(&"16_bit_music")
  check(quote.queued and not quote.can_admit and quote.can_research,"Retired paid queue may finish but not admit")
  var legacy_store:=FeatureStore.new();root.add_child(legacy_store);legacy_store.setup(legacy);legacy_store.open_store()
  check(not legacy_store._research_button.disabled,"Retired paid FIFO remains actionable in actual Store")
  legacy_store._research_button.pressed.emit()
  check(legacy.owns_feature(&"16_bit_music"),"Paid retired FIFO grants its original ID through Store button")
  legacy_store.free()
  check(not legacy.get_future_project_feature_ids().has(&"16_bit_music"),"Retired completion stays out of new projects")
 for version in range(1,5):
  var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://scripts/debug/fixtures/studio_specialties_v%d.json"%version))
  for genre: String in fixture:
   var old_pool:=StudioSpecialties.preview(StringName(genre),version)
   var ids: Array=old_pool.ids.map(func(id): return str(id));ids.sort()
   check(ids==fixture[genre].ids and old_pool.scope==fixture[genre].scope,"Exact historical roster v%d/%s"%[version,genre])
 store.free()
 print("AUDIO_CHECKS ",count," failures ",failures)
 quit(failures)
