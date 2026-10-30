from pathlib import Path
study=Path(__file__).resolve().parent
s=(study.parent/'crown-planning-20261024-v1/analyze.py').read_text(encoding='utf-8')
s=s.replace("report=load(bundle/'run-report.json')","reports={n:load(bundle/n/'run-report.json') for n in ['controls-v2','candidates']}\nreport=reports['controls-v2']\ncasepaths=sorted(p for n in reports for p in (bundle/n/'cases').glob('*/result.json'))\npaths={p.parent.name:p for p in casepaths}")
s=s.replace("for line in (bundle/'experiment.log').read_text(encoding='utf-8',errors='replace').splitlines():", "for line in '\\n'.join((bundle/n/'experiment.log').read_text(encoding='utf-8',errors='replace') for n in reports).splitlines():")
s=s.replace("for path in sorted((bundle/'cases').glob('*/result.json')):","for path in casepaths:")
s=s.replace("check(len(cohort)==5,","check(len(cohort)==6,")
# First-hand rank uses separately independently checked lookahead table.
s=s.replace("if row['arm'].startswith('retained'):rank=int(forecast(ss,hh,quartet,cards)*1000000)+g*100-spread", "if row['arm'].startswith('lookahead'):\n                    decision=next(d for d in n['LOOKAHEAD'] if d['offer']==hand['offer'])\n                    rank=next(r['rank'] for r in decision['ranking'] if r['tokens']==[c['token'] for c in quartet])")
s=s.replace("crown-balance-20261024-v1/candidate-v1", "crown-planning-20261024-v1/candidate-v1")
s=s.replace("if row['arm'] not in ['balanced','skip']:continue", "if row['arm'] not in ['balanced','balanced_redraw','skip']:continue")
s=s.replace("now=load(bundle/'cases'/row['case']/'result.json')","now=load(paths[row['case']])")
s=s.replace("newcp=load(bundle/'cases'/row['case']/'studio_checkpoint.json')['studio_payload']","newcp=load(paths[row['case']].parent/'studio_checkpoint.json')['studio_payload']")
s=s.replace("summary=dict(status='PASS'", "from policy_audit import audit as audit_lookahead\nlookahead_audit=audit_lookahead(notes,check)\ncheck(len({r['frozen_source_identity'] for r in reports.values()})==1,'same frozen source across batches')\nsummary=dict(status='PASS'")
s=s.replace("run_ok=report['ok'],", "run_ok=all(r['ok'] for r in reports.values()),lookahead_audit=lookahead_audit,")
with (study/'analyze.py').open('x',encoding='utf-8',newline='\n') as f:f.write(s)
print('analysis prepared')
