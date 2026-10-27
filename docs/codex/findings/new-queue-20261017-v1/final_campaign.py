from run_checks import *
config={'schema_version':'1','policy':{'script':'res://scripts/simulation/finite_fixture_policy.gd','id':'finite-development-fixture','version':'1'},'cases':[]}
for specialty,seed in [('action',4417),('adventure',4471),('strategy',4714)]:
 config['cases'].append({'schema_version':'1','case_id':specialty+'-'+str(seed),'initial':{'recipe':{'schema_version':1,'studio_id':'queue-'+specialty,'studio_name':'Queue fresh campaign','specialty':specialty,'traits':[],'seed':str(seed)}},'max_commands':100,'target_release_count':2,'policy':{'config':{'genre':specialty,'theme':'fantasy','name_prefix':'Fresh queue','selection':'features_first','hands':{'design':2,'alpha':2,'beta':2}}}})
sim.write_json(BASE/'campaign-config.json',config)
cmd=[sys.executable,'-X','utf8',str(ROOT/'tools/simulate.py'),'run','--config',str(BASE/'campaign-config.json'),'--output',str(BASE/'fresh-campaign-v1'),'--godot',str(GODOT),'--timeout','240']
subprocess.run(cmd,check=True)
for case in config['cases']:
 subprocess.run([sys.executable,'-X','utf8',str(ROOT/'tools/simulate.py'),'replay','--bundle',str(BASE/'fresh-campaign-v1'),'--case',case['case_id'],'--output',str(BASE/('fresh-replay-'+case['case_id'])),'--godot',str(GODOT),'--timeout','240'],check=True)
