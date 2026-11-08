extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+label)
func fresh() -> RunState:
 var s: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"gameplay-restore","studio_name":"Gameplay","specialty":"action","traits":[],"seed":"5517"},root.get_node("CardDatabase").get_development_catalog())
 s.run.finalize_starter_selection();return s.run
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var args:=OS.get_cmdline_user_args()
 var r:=fresh()
 if args.size()==2 and args[0]=="--capture":
  for id: StringName in [&"power_ups",&"score_system"]:check(r.admit_feature_research(r.get_feature_research_quote(id)),"Old root paid admission "+str(id))
  var prior_adapter:=StudioCheckpoint.new();var prior_saved:=prior_adapter.capture(r)
  check(not prior_saved.is_empty() and prior_adapter.validate(prior_saved).is_empty(),"Exact prior paid queue is valid")
  FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"player":prior_saved,"source":Replay.source_identity()}));quit(failures);return
 var g:=FeatureStoreCatalog.graph(r._feature_definitions,r._feature_offers)
 check(not g.has("error"),"Complete graph remains valid")
 for row: Array in [[&"timer_system",&"technology",2,&"design",1,1,95000],[&"inventory_system",&"technology",3,&"design",2,2,170000],[&"categorized_scores",&"design",7,&"technology",2,3,240000]]:
  var e: Dictionary=r._feature_definitions.get(row[0],{})
  check(not e.is_empty(),"Restored new card exists "+str(row[0]))
  if e.is_empty():continue
  check(str(e.phase)=="design" and not e.renewable and not e.has("replaces_id"),"Finite Design non-upgrade "+str(row[0]))
  check([str(e.primary_stat),int(e.primary_value),str(e.secondary_stat),int(e.secondary_value),int(e.scope),int(e.base_price_cents)]==[str(row[1]),row[2],str(row[3]),row[4],row[5],row[6]],"Approved ordered values "+str(row[0]))
  check(e.play_cost_cents==0 and not e.has("min_year") and not e.has("era_year"),"Approved zero direct fee/no added calendar gate")
 if not r._feature_definitions.has(&"categorized_scores"):print("GAMEPLAY_CHECKS ",checks," failures ",failures);quit(failures);return
 check(g.parents[&"categorized_scores"]==[&"timer_system",&"score_system",&"lives_system"],"Exact three ordered parents, no any-three surrogate")
 check(g.parents[&"power_ups"]==[&"categorized_scores"],"Existing Alpha Power-Ups follows Categorized Scores")
 check(r._feature_definitions[&"power_ups"].phase=="alpha" and r._feature_definitions[&"power_ups"].scope==1,"Existing Power-Ups phase and Scope retained")
 # Static definition validation: 3 exact parents allowed; invalid graph forms reject.
 var definitions: Dictionary=r._feature_definitions.duplicate(true)
 var offers: Dictionary=r._feature_offers.duplicate(true)
 offers[&"categorized_scores"].purchase_parents=["timer_system","score_system","lives_system","controls"]
 check(FeatureStoreCatalog.graph(definitions,offers).has("error"),"Four parents remain outside bounded support")
 offers=r._feature_offers.duplicate(true);offers[&"categorized_scores"].purchase_parents=["timer_system","score_system","score_system"]
 check(FeatureStoreCatalog.graph(definitions,offers).has("error"),"Duplicate parent rejects")
 offers=r._feature_offers.duplicate(true);offers[&"categorized_scores"].gameplay_features_required=3
 check(FeatureStoreCatalog.graph(definitions,offers).has("error"),"Exact parents cannot become any-three surrogate")
 offers=r._feature_offers.duplicate(true);offers[&"timer_system"].purchase_parent="categorized_scores"
 check(FeatureStoreCatalog.graph(definitions,offers).has("error"),"Three-parent cycle rejects")
 var credits:=fresh()
 for id: StringName in [&"timer_system",&"score_system",&"lives_system"]:
  credits._owned_features[id]=true;credits._familiarity[id]=2
 var discount:=credits.get_feature_research_quote(&"categorized_scores")
 check(discount.discount_percent==50 and discount.down_cents==120000 and discount.due_cents==60000,"Three parents share one50% cap; deposit and installment cents exact")
 var queued:=fresh();queued._owned_features[&"score_system"]=true;queued._owned_features[&"lives_system"]=true
 check(queued.admit_feature_research(queued.get_feature_research_quote(&"timer_system")),"Timer may be queued legally")
 check(not queued.get_feature_store_offer(&"categorized_scores").unlocked,"Queued Timer is not an owned parent")
 var store:=FeatureStore.new();root.add_child(store);store.setup(r)
 check(store._nodes.size()==50 and store._nodes[&"categorized_scores"].get_node("AndGate").text=="AND: 3 parents","50 active nodes and explicit three-parent badge")
 check(not r.owns_feature(&"timer_system") and not r.owns_feature(&"inventory_system") and not r.owns_feature(&"categorized_scores"),"No automatic new Store grants")
 store.free()
 # Explicit funded transaction fixture; not new-game solvency acceptance.
 check(r.add_cash_cents(2000000,&"other_income",&"gameplay_test_funding"),"Recorded mechanics funding")
 for id: StringName in [&"power_ups",&"categorized_scores"]:
  var before:=Replay.digest(Replay.freeze(r))
  check(not r.admit_feature_research(r.get_feature_research_quote(id)),"Missing prerequisites reject "+str(id))
  check(Replay.digest(Replay.freeze(r))==before,"Rejection preserves state/RNG")
 for id: StringName in [&"timer_system",&"inventory_system",&"score_system",&"lives_system"]:
  check(r.admit_feature_research(r.get_feature_research_quote(id)),"Legal parent admission "+str(id))
  check(r.research_feature(r.get_feature_research_quote(id)),"Legal parent Research "+str(id))
 for missing: StringName in [&"timer_system",&"score_system",&"lives_system"]:
  r._owned_features.erase(missing)
  check(not r.get_feature_store_offer(&"categorized_scores").unlocked,"Each of three AND arms required "+str(missing))
  r._owned_features[missing]=true
 for id: StringName in [&"categorized_scores",&"power_ups"]:
  check(r.admit_feature_research(r.get_feature_research_quote(id)),"Legal child admission "+str(id))
  check(r.research_feature(r.get_feature_research_quote(id)),"Legal child Research "+str(id))
 var a:=StudioCheckpoint.new();var saved:=a.capture(r)
 check(not saved.is_empty() and a.hydrate(saved)!=null,"Current real transactions round trip")
 var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/gameplay-adoption-20261028-v1/predecessor.json"))
 var old:=a.hydrate(prior.player)
 check(old!=null,"Exact prior Power-Ups/Score queues restore")
 if old!=null:
  var expected: Dictionary=prior.player.duplicate(true);expected.content_revision=a.revision()
  check(a.capture(old)==expected,"Every prior ownership/payment/history/finance/RNG field preserved")
  for id: StringName in [&"power_ups",&"score_system"]:check(old.research_feature(old.get_feature_research_quote(id)) and old.owns_feature(id),"Old paid root queue finishes without new parents "+str(id))
  check(not old.owns_feature(&"categorized_scores") and not old.owns_feature(&"timer_system"),"No free parent grants on migration")
 print("GAMEPLAY_CHECKS ",checks," failures ",failures);quit(failures)
