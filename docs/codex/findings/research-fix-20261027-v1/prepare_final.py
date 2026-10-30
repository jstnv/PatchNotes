from pathlib import Path
import hashlib,json,subprocess
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
files=['scripts/finance/studio_finance_ledger.gd','scripts/sales/released_game_sales.gd','scripts/market/rival_trial.gd','scripts/market/rival_world.gd','scripts/run_state.gd','scripts/ui/feature_store.gd','scripts/ui/gameplay_hud.gd','scripts/phases/studio_phase.gd','scripts/persistence/checkpoint_write.gd','scripts/simulation/begin_project.gd','scripts/simulation/development_session.gd','scripts/simulation/launch_settlement.gd','scripts/simulation/transaction_projection.gd']
for name in files:
 p=ROOT/'patch-notes'/name
 prior=subprocess.check_output(['git','show','HEAD:patch-notes/'+name],cwd=ROOT)
 if b'\r\n' in prior:
  p.write_bytes(p.read_bytes().replace(b'\r\n',b'\n').replace(b'\n',b'\r\n'))
probe=(OUT.parent/'research-latency-20261027-v1/research_latency.gd').read_text(encoding='utf-8')
probe=probe.replace('var ids: Array=run._feature_definitions.keys();ids.sort()', '''var ids: Array=run._feature_definitions.keys()
\t\t\tids.sort_custom(func(a,b):return str(a)<str(b))
\t\t\t# Pin the original regression actions across editor/export StringName tables.
\t\t\tfor preferred: StringName in [&"dialogue",&"character_backstories",&"secrets"]:
\t\t\t\tids.erase(preferred);ids.push_front(preferred)''')
(OUT/'research_latency.gd').write_text(probe,encoding='utf-8')
maintained=probe.replace('[96,192]','[96]').replace('int(OS.get_environment("PN_CHECKPOINT_TEST_PORT"))','int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")) if not OS.get_environment("PN_CHECKPOINT_TEST_PORT").is_empty() else 47923')
maintained=maintained.replace('Genuine four-release c96 old-save CPU fixture, then legal calendar growth to192 with real rivals.','Genuine four-release c96 old-save CPU fixture; three consecutive legal acquisitions with real rivals. Separate extended probe covers cycle192.')
(ROOT/'patch-notes/scripts/debug/verify_research_latency.gd').write_text(maintained,encoding='utf-8')
fixture=ROOT/'tools/fixtures/research_latency_pre_fix.json'
fixture.write_bytes((OUT.parent/'discard-menu-20261027-v1/final-cold.json').read_bytes())
proof={'sha256':hashlib.sha256(fixture.read_bytes()).hexdigest(),'source_identity':'25dc0a8892df95b95b93690b5224d12e4242a97426ad5d4dbf4c98d42696af59','producer':'docs/codex/findings/discard-menu-20261027-v1/final-cold.json','purpose':'Actual pre-fix saved DTO for candidate exact-pair compatibility proof; no production source override approval implied.'}
fixture.with_suffix('.provenance.json').write_text(json.dumps(proof,indent=2),encoding='utf-8')
test=ROOT/'patch-notes/scripts/debug/verify_research_compatibility_candidate.gd'
test.write_text(test.read_text(encoding='utf-8').replace('res://../docs/codex/findings/discard-menu-20261027-v1/final-cold.json','res://../tools/fixtures/research_latency_pre_fix.json'),encoding='utf-8')
