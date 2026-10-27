extends "res://scripts/debug/verify_primitive_branches.gd"
func _initialize()->void:
 await process_frame
 catalog=root.get_node("CardDatabase").get_development_catalog()
 var result:={}
 for child:StringName in [&"local_leaderboards",&"enemies",&"general_combat",&"difficulty_levels"]:
  var run:RunState=fresh().run
  run.add_cash_cents(2000000,&"other_income",&"fixture")
  run.finalize_starter_selection()
  run._owned_features.erase(child)
  for parent:StringName in [&"high_scores",&"turn_based_combat",&"scripted_ai"]:run._owned_features.erase(parent)
  if child==&"enemies":run._owned_features.erase(&"lives_system")
  if child==&"general_combat":run._owned_features.erase(&"enemies")
  var q:=run.get_feature_research_quote(child)
  check(q.can_admit and run.admit_feature_research(q),"Actual old admission "+str(child))
  result[str(child)]=StudioCheckpoint.new().capture(run)
  check(run.research_feature(run.get_feature_research_quote(child)),"Old completion "+str(child))
  result["owned_"+str(child)]=StudioCheckpoint.new().capture(run)
 var partial:RunState=fresh().run
 partial.add_cash_cents(2000000,&"other_income",&"partial-fixture")
 partial.finalize_starter_selection()
 partial._owned_features.erase(&"difficulty_levels")
 partial._owned_features.erase(&"turn_based_combat")
 partial._owned_features.erase(&"scripted_ai")
 check(partial.admit_feature_research(partial.get_feature_research_quote(&"difficulty_levels")),"Old partial fixture admission")
 partial._feature_research[0].actions=2 # Hypothetical historical duration, not a new live rule.
 check(partial.research_feature(partial.get_feature_research_quote(&"difficulty_levels")),"Old partial first installment")
 result["partial_difficulty"]=StudioCheckpoint.new().capture(partial)
 FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
 print("PRIOR_GAMEPLAY checks=%d failures=%d"%[checks,failures]);quit(failures)
