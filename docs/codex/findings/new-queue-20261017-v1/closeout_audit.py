from run_checks import *
import hashlib

manifest=sim.read_json(BASE/'build-v1/build-manifest.json')
assert all(sim.sha(ROOT/'patch-notes'/key)==value for key,value in manifest['included'].items())
pack=sim.read_json(BASE/'build-v1/pack-manifest-verified.json')
assert pack['count']==301 and pack['all_payload_md5_valid'] and not pack['missing_runtime_files'] and not pack['unexpected_files']
commands=[]
for name in ['clean-import','export-release','headless-startup']:
 data=sim.read_json(BASE/('build-v1/'+name+'.command.json'))
 assert data['exit']==0 and not data.get('errors',[])
 commands.append(name)
logs=[];processes=[]
for attempt in [1,2]:
 out=BASE/('ai-variety-rivals-'+str(attempt))
 record=sim.read_json(out/'rival-verifier.command.json')
 assert record['exit']==0 and not record['errors']
 lines=(out/'rival-verifier.log').read_text(encoding='utf-8').splitlines()
 evidence=[line for line in lines if line.startswith(('MARKET_SHADOW_','RIVAL_TRIAL_ACTIVATION'))]
 assert evidence[-1]=='RIVAL_TRIAL_ACTIVATION checks=213 failures=0 cycles=20 restore_at=0 releases=4'
 logs.append(evidence);processes.append(record)
assert logs[0]==logs[1]
releases=[line for line in logs[0] if line.startswith('MARKET_SHADOW_RELEASE')]
sales=[line for line in logs[0] if line.startswith('MARKET_SHADOW_SALES')]
report=sim.read_json(BASE/'ai-variety-run-v2/run-report.json')
assert report['ok']
replay=sim.read_json(BASE/'ai-variety-replay-v1/run-report.json')
assert replay['ok']
sim.write_json(BASE/'closeout-audit.json',{
 'canonical_export_inputs_byte_current':len(manifest['included']),
 'package_entries':pack['count'],'build_commands_passed':commands,
 'variety_candidate':report['variant'],'variety_processes':processes,
 'variety_repeat_evidence_exact':True,'variety_releases':releases,
 'shadow_sales_rows':len(sales),'shadow_sales_factor_basis_points':sorted(set(int(re.search(r' bp=(\d+)',line).group(1)) for line in sales)),
 'variety_player_fresh_replay_ok':True,
 'scope':'Private Theme variety and shadow arithmetic only; no active pressure or broad policy/quality verdict.'})
print(json.dumps({'build_inputs':len(manifest['included']),'variety_exact_repeat':True,'releases':len(releases),'sales_rows':len(sales)}))
