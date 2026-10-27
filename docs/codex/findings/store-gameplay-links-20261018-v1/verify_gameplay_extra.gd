extends "res://scripts/debug/verify_primitive_branches.gd"
func _initialize()->void:
 await process_frame
 catalog=root.get_node("CardDatabase").get_development_catalog()
 var prior:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_GAMEPLAY_PRIOR_SAVES")))
 var codec:=StudioCheckpoint.new()
 var run:=codec.hydrate(prior.partial_difficulty)
 check(run!=null,"Historical partially-paid Difficulty queue restores")
 if run==null:quit(1);return
 var expected:Dictionary=prior.partial_difficulty.duplicate(true)
 expected.content_revision=codec.revision()
 check(codec.capture(run)==expected,"Partial payments, state, RNG and old ownership remain byte-equivalent apart from revision")
 var q:=run.get_feature_research_quote(&"difficulty_levels")
 var control:=codec.hydrate(codec.capture(run))
 var cycle:=run.get_completed_run_cycles()
 check(q.paid_cents==82500 and q.due_cents==27500 and q.remaining_actions==1,"Only original final balance remains due")
 check(control.complete_productive_action(Callable(),-int(q.due_cents),q.cycle,&"",&"store",StringName("%s:%d"%[q.entry_id,q.completed])),"Native final-installment finance control")
 check(run.research_feature(q) and run.get_studio_finance_snapshot()==control.get_studio_finance_snapshot() and run.get_completed_run_cycles()==cycle+1,"Final original installment commits once with normal rent boundary and no new parents")
 check(not run.owns_feature(&"turn_based_combat") and not run.owns_feature(&"scripted_ai"),"Migration grants no parents")
 run=fresh().run
 run.finalize_starter_selection()
 run._owned_features.erase(&"difficulty_levels")
 run._owned_features.erase(&"turn_based_combat")
 run._owned_features.erase(&"scripted_ai")
 var offer:=run.get_feature_store_offer(&"difficulty_levels")
 check(offer.missing_parents==[&"turn_based_combat",&"scripted_ai"] and offer.prerequisite.contains("Turn-Based Combat") and offer.prerequisite.contains("Scripted AI"),"Exact missing parent IDs and names")
 for id:StringName in [&"controls",&"power_ups",&"score_system"]:run._owned_features[id]=true
 check(not run.get_feature_research_quote(&"difficulty_levels").can_admit,"Three unrelated Gameplay cards never substitute")
 run._owned_features[&"general_combat"]=true
 run._owned_features[&"scripted_ai"]=true
 check(run.admit_feature_research(run.get_feature_research_quote(&"turn_based_combat")),"Real prerequisite enters paid research queue")
 var before:=state(run)
 check(not run.admit_feature_research(run.get_feature_research_quote(&"difficulty_levels")) and state(run)==before,"Queued Turn-Based Combat is not ownership; rejection atomic")
 print("GAMEPLAY_EXTRA checks=%d failures=%d"%[checks,failures]);quit(failures)
