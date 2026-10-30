from run import *
s=(HERE/'policy.gd').read_text()
s=s.replace('if config.arm=="passes":','if config.arm=="passes_then_balance" and int(state.hand_count)==0:')
s=s.replace('if config.arm!="naive" and rank>best:', 'if not (config.arm=="naive_then_balance" and int(state.hand_count)==0) and rank>best:')
(HERE/'witness.gd').write_text(s,encoding='utf-8')
cfg=load(HERE/'branches-4522.json');cases=[]
for arm in ['naive_then_balance','passes_then_balance']:
    c=json.loads(json.dumps(cfg['cases'][0]));c['case_id']=arm+'-4522'
    c['policy']['config'].update(arm=arm,label=c['case_id']);c['study']['arm']=arm
    cases.append(c)
write(HERE/'witness.json',dict(schema_version='1',policy=dict(script='witness.gd',id='crown-brief-targeted-full-witness',version='1'),cases=cases))
write(HERE/'witness-pins.json',dict(policy=sha(HERE/'witness.gd'),config=sha(HERE/'witness.json'),plan=sha(HERE/'FULL-WITNESS-ADDENDUM.md')))
