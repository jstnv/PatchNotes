"""Derive this study harness from the retained adoption acceptance harness.

Only files in this finding folder are written. No canonical source is changed.
"""
from pathlib import Path
import hashlib
import json

OUT = Path(__file__).resolve().parent
BASE = OUT.parent / 'market-adoption-20261018-v1' / 'acceptance.gd'
source = BASE.read_text(encoding='utf-8')

def replace_once(old, new):
    global source
    assert source.count(old) == 1, (old, source.count(old))
    source = source.replace(old, new)

replace_once('const COMMAND_LIMIT := 180', 'const COMMAND_LIMIT := 180\nconst CYCLE_LIMIT := 48\nconst WALL_LIMIT_US := 180000000\nconst RELEASE_LIMIT := 6')
replace_once('var starting_source := ""', 'var starting_source := ""\nvar study_started := 0\nvar study_seed := ""\nvar review_counterfactuals: Array = []\nvar sales_counterfactuals: Array = []\nvar actual_publications: Array = []')
replace_once('starting_source = Replay.source_identity()', 'starting_source = Replay.source_identity()\n\tstudy_started = Time.get_ticks_usec()\n\tstudy_seed = _arg("--seed=", "4417")\n\texpect(starting_source == _arg("--source="), "explicit approved source identity")\n\texpect(study_seed in ["4417","4418"], "predeclared seed")\n\tif failures: _finish({}); return')
replace_once('"studio_id":"market-acceptance-"+route,"studio_name":"Market "+route,', '"studio_id":"market-exposure-"+route+"-"+study_seed,"studio_name":"Exposure "+route+" "+study_seed,')
replace_once('"traits":["family_funding","graduate"] if route == "strong" else ["cult_following"],"seed":"4417"}', '"traits":["cult_following"],"seed":study_seed}')
replace_once('var target_releases := 2 if route == "strong" else 3', 'var target_releases := RELEASE_LIMIT')
replace_once('for index in range(COMMAND_LIMIT):\n\t\tif player.in_studio', 'for index in range(COMMAND_LIMIT):\n\t\tif world.cycle >= CYCLE_LIMIT or Time.get_ticks_usec()-study_started >= WALL_LIMIT_US:\n\t\t\tfailure_reason = "Predeclared cycle or wall bound reached"; break\n\t\tif player.in_studio')
replace_once('"three complete legal player releases"', '"six complete legal player releases"')
replace_once('if output.is_empty() or route not in ["action-war","action-fantasy","puzzle-war","puzzle-fantasy","strong"]:', 'if output.is_empty() or route not in ["action-war","action-fantasy","puzzle-war","puzzle-fantasy"]:')
replace_once('var review:=project.get_review_result()', 'var review:=project.get_review_result()\n\tvar frozen_inputs := {"cores":[],"scope_completion":review.get_scope_completion(),"bug_multiplier":review.get_bug_multiplier(),"variance_modifier":review.get_variance_modifier(),"variance_roll":review.get_variance_roll(),"required_scope":project.get_required_scope(),"scope":project.get_current_scope(),"remaining_bugs":project.get_remaining_bugs()}\n\tfor category in range(4): frozen_inputs.cores.append(project.get_core_score(category))\n\tvar actual_recomputed := _fixed_review(frozen_inputs, standards)\n\tvar base_recomputed := _fixed_review(frozen_inputs, base)\n\texpect(is_equal_approx(actual_recomputed.final_review, review.get_final_review()), "fixed-input Review reproduces actual frozen result")\n\treview_counterfactuals.append({"release_id":str(id),"cycle":world.cycle,"inputs":frozen_inputs,"actual_standards":standards,"base_standards":base,"actual":actual_recomputed,"genre_base_only":base_recomputed,"actual_minus_base_tenths":roundi((actual_recomputed.final_review-base_recomputed.final_review)*10)})')
replace_once('for index in range(tape.steps.size()):\n\t\tvar expected:', 'for index in range(tape.steps.size()):\n\t\tif Time.get_ticks_usec()-study_started >= WALL_LIMIT_US:\n\t\t\tfailure_reason = "Predeclared replay wall bound reached"; expect(false,failure_reason); break\n\t\tvar expected:')
replace_once('var ending_source := Replay.source_identity()', 'if player != null and world != null: _counterfactual_report()\n\tvar ending_source := Replay.source_identity()\n\texpect(starting_source == ending_source,"unchanged source throughout study")')
replace_once('"harness_sha256":FileAccess.get_sha256(get_script().resource_path)', '"snapshots":snapshots,"actual_publications":actual_publications,"review_counterfactuals":review_counterfactuals,"sales_counterfactuals":sales_counterfactuals,"bounds":{"commands":COMMAND_LIMIT,"cycles":CYCLE_LIMIT,"wall_us":WALL_LIMIT_US,"target_releases":RELEASE_LIMIT},"harness_sha256":FileAccess.get_sha256(get_script().resource_path)')
source += (OUT/'counterfactuals.gd.txt').read_text(encoding='utf-8')
(OUT/'exposure.gd').write_text(source, encoding='utf-8')
(OUT/'harness-provenance.json').write_text(json.dumps({'base':str(BASE),'base_sha256':hashlib.sha256(BASE.read_bytes()).hexdigest(),'generated_normalized_lf_sha256':hashlib.sha256(source.encode()).hexdigest(),'generated_file_bytes_sha256':hashlib.sha256((OUT/'exposure.gd').read_bytes()).hexdigest()}, indent=2)+'\n',encoding='utf-8')
print('Prepared study harness only; no Godot process launched.')
