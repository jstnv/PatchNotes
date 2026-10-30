from setup import HERE,PREV,replace_once as rep
import ast,json
def save(name,text):
    ast.parse(text,filename=name)
    with (HERE/name).open('x',encoding='utf-8') as f:f.write(text)

def main():
    text=(PREV/'analyze.py').read_text(encoding='utf-8')
    text=rep(text,"for arm in ['control','candidate']:","for arm in ['control','reserved','candidate']:")
    anchor="        pairs.append({'pair':pair,"
    extra="""        reserved_report=comparison.compare(bundle,'reserved-'+pair,'candidate-'+pair)
        write(HERE/(pair+'-reserved-comparison.json'),reserved_report)
        (HERE/(pair+'-reserved-comparison.md')).write_text(comparison.markdown(reserved_report),encoding='utf-8')
"""
    text=rep(text,anchor,extra+anchor);save('analyze.py',text)
    text=(PREV/'audit_policy.py').read_text(encoding='utf-8')
    start=text.index("        config=load(HERE/(pair+'.json'));left,right=config['cases']")
    end=text.index("    for row in analysis['rows']:",start)
    text=text[:start]+'''        config=load(HERE/(pair+'.json'));cases=config['cases']
        check(all(c['initial']==cases[0]['initial'] for c in cases),pair+' identical recipes')
        configs=[]
        for c in cases:
            cfg=c['policy']['config'].copy()
            for key in ['label','reserve_beta_redraw','first_search_redraw']:cfg.pop(key)
            configs.append(cfg)
        check(all(c==configs[0] for c in configs) and configs[0]['qa_extension'] and not configs[0]['core_target'],pair+' only timing differs')
'''+text[end:]
    text=rep(text,"reserved=row['arm']=='candidate'","reserved=row['arm']!='control'\n        first=row['arm']=='candidate'")
    text=rep(text,"not n['qa_extra'] and not n['reserved_redraw']","not n['qa_extra'] and not n['reserved_redraw'] and not n['first_redraw']")
    anchor="            check(n['reserved_redraw']==(reserved and opportunity),cid+' exact reserved trigger')"
    text=rep(text,anchor,anchor+"\n            opening=active and phase=='beta' and counts[key]==0 and n['cash']>=4*n['monthly_rent_cents'] and 'search_for_bugs' not in visible and redraws[key]==0 and d['redraws']>0\n            check(n['first_redraw']==(first and opening),cid+' exact first-hand trigger')")
    text=rep(text,"if phase=='beta':check(n['reserved_redraw']==reserved,cid+' Beta timing authority')","if phase=='beta':check((n['reserved_redraw'] or n['first_redraw'])==reserved,cid+' Beta timing authority')")
    text=rep(text,"                if n['reserved_redraw']:\n                    check(opportunity and ext[key]<2,cid+' extension budget and trigger')","                if n['reserved_redraw'] or n['first_redraw']:\n                    check((opening if n['first_redraw'] else opportunity) and ext[key]<2,cid+' timing budget and trigger')")
    text=rep(text,"events.append({'case':cid,","events.append({'timing':'first' if n['first_redraw'] else 'late','case':cid,")
    save('audit_policy.py',text)
    text=(PREV/'summarize.py').read_text(encoding='utf-8')
    text=rep(text,"for arm in ['control','candidate']:","for arm in ['control','reserved','candidate']:")
    anchor="    result={'complete':"
    extra="""    for arm,data in arms.items():
        ps=[p for p in projects if p['case'].startswith(arm+'-')]
        data['no_effect_all_debug_openers']=sum(bool(p['beta_hands']) and set(p['beta_hands'][0]['selected'])=={'debug'} and p['beta_hands'][0]['discovered']==0 and p['beta_hands'][0]['fixed']==0 for p in ps)
        ev=[e for e in p_audit_events if e['case'].startswith(arm+'-')]
        data['redraw_attempts']={timing:{'count':sum(e['timing']==timing for e in ev),'search_hits':sum(e['timing']==timing and e['search_hit'] for e in ev)} for timing in ['first','late']}
"""
    text=rep(text,anchor,extra+anchor)
    text=rep(text,"a=load(HERE/'analysis.json');p=load(HERE/'policy-audit.json');arms={};projects=[];cache={}","a=load(HERE/'analysis.json');p=load(HERE/'policy-audit.json');p_audit_events=p['reserved_redraws'];arms={};projects=[];cache={}")
    save('summarize.py',text)
    for name in ['run_verification.py','verify.py']:
        text=(PREV/name).read_text(encoding='utf-8').replace('redraw-cold-next','first-cold-next')
        if name=='verify.py':
            text=rep(text,'CROWN-BETA-REDRAW-PLAN-2026-10-24-v1.md','CROWN-FIRST-BETA-PLAN-2026-10-24-v1.md')
            text=rep(text,"len(a['rows'])==4","len(a['rows'])==6")
        save(name,text)
    print(json.dumps({'prepared':['analyze.py','audit_policy.py','summarize.py','run_verification.py','verify.py']}))
if __name__=='__main__':main()
