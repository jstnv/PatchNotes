from setup import *
import time,shutil
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-search-brief-20261025-v1')
ACCESS=HERE.parent/'crown-search-access-20261025-v1'
ACCESSRAW=RAW.parent/'crown-search-access-20261025-v1'
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def execute(name,args):
 assert not (HERE/(name+'-command.json')).exists(),name
 write(HERE/(name+'-command.json'),args);start=time.time()
 with (HERE/(name+'-driver.log')).open('w',encoding='utf-8') as f:r=subprocess.run(args,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT)
 write(HERE/(name+'-exit.json'),dict(exit_code=r.returncode,seconds=time.time()-start));print(name,r.returncode,flush=True);return r.returncode
def prepare():
 rows=load(ACCESS/'analysis.json')['rows'];assert len(rows)==12
 chosen=[]
 for genre in ['action','puzzle','simulation']:
  candidates=[r for r in rows if r['case'].startswith(genre+'-') and r['access']]
  if candidates:chosen.append(sorted(candidates,key=lambda r:(r['arm']!='cash6',r['access']['cycle'],r['case']))[0])
 cases=[]
 for row in chosen:
  case=next(c for c in load(ACCESS/(row['pair']+'.json'))['cases'] if c['case_id']==row['case'])
  case['case_id']='prefix-'+row['case'];case['target_release_count']=int(row['access']['release'].split(':')[-1]);cases.append(case)
 write(HERE/'selection.json',chosen)
 write(HERE/'prefix.json',dict(schema_version='1',policy=dict(script='res://scripts/debug/csa_access.gd',id='crown-search-quality',version='2'),cases=cases))
 shutil.copyfile(HERE/'probe.gd',VAR/'project/scripts/debug/crown_search_probe.gd')
 policy=(HERE.parent/'crown-twohand-20261025-v1/policy.gd').read_text(encoding='utf-8')
 policy=policy.replace('res://scripts/debug/cb2_access.gd','res://scripts/debug/csa_access.gd')
 a=policy.index('\tp.legacy=Base.factory(');b=policy.index('\n',a);policy=policy[:a]+'\tp.legacy=Base.factory(cfg)'+policy[b:]
 policy=policy.replace(' and briefs<3 and rep<2000:',' and briefs<3:')
 needle='\treturn legacy.call(view)'
 insert='''\t\tfor row: Dictionary in view.studio_actions.contract_search:
\t\t\tif row.publisher_id==&"crown_quill" and row.work==&"brief" and not row.quote.is_empty():
\t\t\t\tnote("SEARCH",{"cycle":view.run_cycle,"cash":view.cash_cents,"quote":row.quote})
\t\t\t\treturn {"type":&"search_contracts","payload":{"quote":row.quote}}
\t\treturn fail("Crown search unavailable before3 Briefs")
'''
 assert needle in policy;policy=policy.replace(needle,insert+needle)
 (HERE/'policy.gd').write_text(policy,encoding='utf-8')
 sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as sv
 meta,base,current,integrity=sv.load_variant(VAR);write(HERE/'execution-pin.json',dict(meta=meta,identity=sv.identity(current),changes=sv.delta(base,current),integrity=integrity))
 print('selected',[(r['case'],r['access']) for r in chosen])
def branches():
 cases=[]
 for prefix in load(HERE/'prefix.json')['cases']:
  folder=RAW/'prefix/cases'/prefix['case_id'];result=load(folder/'result.json')
  if result['status']!='completed' or not (folder/'studio_checkpoint.json').exists():continue
  assert max(float(r['metadata']['review']['final_review']) for r in result['outcome']['releases'])>=7
  for arm in ['skip','mean']:
   c=json.loads(json.dumps(prefix));c['case_id']=prefix['case_id'].replace('prefix-',arm+'-');c['initial']={'checkpoint':load(folder/'studio_checkpoint.json')};c['target_release_count']=result['final_release_count']+1;c['max_commands']=100;c['study']={'pair_id':prefix['case_id'],'arm':arm};c['policy']['config'].update(arm=arm,label=c['case_id'],starting_reputation=0);cases.append(c)
 write(HERE/'branches.json',dict(schema_version='1',policy=dict(script='policy.gd',id='crown-search-brief-public-mean256',version='1'),cases=cases))
def run(name):return execute(name,[sys.executable,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/(name+'.json')),'--output',str(RAW/name),'--timeout','600','--godot',GODOT])
if __name__=='__main__':
 action=sys.argv[1]
 if action=='prepare':prepare()
 elif action=='branches':branches()
 elif action=='run':run(sys.argv[2])
 elif action=='replay':
  case=sys.argv[2];execute('replay-'+case,[sys.executable,'tools/simulate.py','replay','--bundle',str(RAW/'branches'),'--case',case,'--output',str(RAW/('replay-'+case)),'--timeout','240','--godot',GODOT])
