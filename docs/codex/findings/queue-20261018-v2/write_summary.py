from pathlib import Path
import json, hashlib, statistics, math, re, subprocess

out=Path(__file__).resolve().parent
root=out.parents[3]
read=lambda p:json.loads(p.read_text())
ai=read(out/'ai-compare-final.json')
rows=[]
for phase in ['first','second']:
    for result in ai[phase]['results']:
        saved=read(out/('ai-compare-final.json.'+phase)/result['case_id']/'studio_checkpoint.json')['studio_payload']['run']
        release=saved['released_games'][-1]['value']
        meta=saved['release_metadata'][-1]['value']
        rows.append({'phase':phase,'case':result['case_id'],'cash_cents':int(saved['cash_cents']),'cycle':int(saved['completed_run_cycles']),'fans':int(saved['fanbase']['fans']),'review_tenths':int(release['review_tenths']),'bugs':int(meta['review']['remaining_bugs']),'scope':int(meta['review']['scope']),'units':int(release['total_units']),'earned_cents':int(release['entitlement_cents']),'settled_cents':int(release['settled_cents']),'portfolio_earned_cents':sum(int(v['value']['entitlement_cents']) for v in saved['released_games']),'portfolio_settled_cents':sum(int(v['value']['settled_cents']) for v in saved['released_games'])})
timing={}
for mode in ['reference','trial']:
    worlds=[w for w in ai['worlds'] if w['mode']==mode]
    values=sorted(v for w in worlds for v in w['world_cycle_us'])
    timing[mode]={'total20_cycle_us':[sum(w['world_cycle_us']) for w in worlds],'total_policy_us':[sum(w['policy_us']) for w in worlds],'median_cycle_us':statistics.median(values),'p95_cycle_us':values[math.ceil(.95*len(values))-1],'json_characters':[w['world_bytes'] for w in worlds]}
(out/'ai-summary.json').write_text(json.dumps({'source':ai['source'],'receipts':rows,'timing':timing},indent=2))
paths=['scripts/studio_specialties.gd','scripts/run_state.gd','scripts/persistence/checkpoint_schema.gd','scripts/persistence/studio_checkpoint.gd','scripts/market/rival_world_checkpoint.gd','scripts/phases/main_menu.gd','scripts/market/rival_trial.gd','scripts/market/rival_synergy_choice.gd','scripts/market/rival_beta_synergy_choice.gd','scripts/debug/verify_studio_specialties.gd','scripts/debug/fixtures/studio_specialties_v2.json','scripts/debug/verify_studio_roster_versions.gd','scripts/debug/verify_rival_synergy.gd','scripts/debug/verify_design_phase.gd','scripts/debug/verify_cult_following.gd','scripts/debug/cult_restart_probe.gd','scripts/debug/verify_contract_challenge_publishers.gd']
manifest={str(p.relative_to(root)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in [root/'patch-notes'/name for name in paths]}
(out/'final-source.json').write_text(json.dumps({'branch':'main','head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),'mechanic_source':ai['source'],'modified_by_this_pass':manifest},indent=2))
labels=['studio_specialties','feature_store','feature_research','primitive_branches','store_cone_parents','gameplay-fixed','research_integration','founder_victory','cult-fixed','contracts-fixed','final-rival_gameplay_activation','final-studio_checkpoint','final-genre_checkpoint','final-studio_folder_menu','final-legacy_world','oracle-final-design_command','oracle-final-alpha_command','oracle-final-beta_command','oracle-final-production_extraction','oracle-final-beta_qa_specialization','oracle-final-beta_balanced_operations','roster-closeout','ai-compare-final','ai-world-final','ai-migration-final','native-final']
results=[]
for label in labels:
    data=read(out/(label+'-run.json'))
    assert data['exit']==0 and not data['errors'],label
    evidence=[line for line in data['tail'] if re.search(r'checks=|verification passed|characterization:|trace capture:|scenarios \(',line)]
    results.append({'label':label,'script':data['command'][data['command'].index('--script')+1],'exit':data['exit'],'errors':data['errors'],'summary':evidence})
(out/'focused-results.json').write_text(json.dumps(results,indent=2))
table=['| Run | Result | Evidence |','|---|---|---|']
for row in results:
    table.append('| '+row['label']+' | PASS | ['+('; '.join(row['summary']) or 'exit0; no error signatures')+']('+row['label']+'-run.json) |')
(out/'CHECKS.md').write_text('# Focused verification — 2026-10-18\n\nThese are 26 passing selected runs, not a refreshed whole-project gate. Original commands and process results are linked. Logs retain expected rejection warnings and baseline shutdown leaks. Earlier failed attempts remain alongside the final runs.\n\n'+'\n'.join(table)+'\n\n[Fresh campaigns and six fresh replays](closeout-runs.json) · [Exact player state/RNG comparison](player-parity.json) · [Earlier batch and source stages](batch-results.json).\n',encoding='utf-8')
print('SUMMARY',len(paths),'files',len(results),'passing selected runs',len(rows),'AI release receipts')
