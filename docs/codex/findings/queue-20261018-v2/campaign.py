from pathlib import Path
import hashlib,json,subprocess,sys
out=Path('docs/codex/findings/queue-20261018-v2').resolve()
policy=Path('patch-notes/scripts/simulation/finite_fixture_policy.gd')
identity={'id':'finite-development-fixture','version':'1','source_identity':hashlib.sha256(policy.read_bytes()).hexdigest()}
config={'schema_version':'1','policy':{'script':'res://scripts/simulation/finite_fixture_policy.gd',**identity},'cases':[]}
for i,genre in enumerate(['action','strategy','simulation','sports']):
    config['cases'].append({'schema_version':'1','case_id':genre,'initial':{'recipe':{'schema_version':1,'studio_id':'roster-'+genre,'studio_name':'Roster '+genre,'specialty':genre,'traits':[],'seed':str(4417+i)}},'max_commands':120,'target_release_count':3,'policy':{**identity,'config':{'genre':genre,'theme':'fantasy','name_prefix':'Roster route','selection':'features_first','hands':{'design':2,'alpha':2,'beta':2}}}})
(out/'campaign-config.json').write_text(json.dumps(config,indent=2))
args=['campaign-final','res://scripts/debug/campaign_experiment_cli.gd','--config='+str(out/'campaign-config.json'),'--output-dir='+str(out/'campaign-cases'),'--output='+str(out/'campaign-report.json')]
r=subprocess.run([sys.executable,str(out/'run.py'),*args]);print('CAMPAIGN_EXIT',r.returncode,flush=True)
if r.returncode==0:
    for genre in ['action','strategy','simulation','sports']:
        folder=out/'campaign-cases'/genre
        subprocess.run([sys.executable,str(out/'run.py'),'replay-'+genre,'res://scripts/debug/campaign_replay_cli.gd','--case='+str(folder/'case.variant.json'),'--tape='+str(folder/'replay.tape.json'),'--output='+str(out/('replay-'+genre+'.json'))],check=True)
