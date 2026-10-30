from setup import HERE, write
import analyze,audit_policy,json,contextlib,io
with contextlib.redirect_stdout(io.StringIO()):
    analyze.main();audit_policy.main()
a=json.loads((HERE/'analysis.json').read_text());p=json.loads((HERE/'policy-audit.json').read_text());result={'complete':a['complete'],'study_checks':a['checks'],'policy_checks':p['checks'],'experiments':{},'rows':[]}
for exp in ['qa','core']:
    result['experiments'][exp]={}
    for arm in ['control','candidate']:
        rows=[r for r in a['rows'] if r['pair'].startswith(exp+'-') and r['arm']==arm];q=[q for r in rows for q in r['review_details']]
        result['experiments'][exp][arm]={'cases':len(rows),'completed':sum(r['ok'] for r in rows),'unlocked':sum(r['unlocked'] is True for r in rows),'commands':sum(r['commands'] for r in rows),'accepted':sum(r['accepted_commands'] for r in rows),'mean_review':sum(v['final_review'] for v in q)/max(1,len(q)),'mean_bugs':sum(v['remaining_bugs'] for v in q)/max(1,len(q)),'full_scope':sum(v['scope']>=v['required_scope'] for v in q),'max_arrears':max((r['arrears_max'] for r in rows),default=0)}
for r in a['rows']:
    result['rows'].append({k:r[k] for k in ['case','ok','error','commands','first_qualifying_release','first_qualifying_cycle','reviews','cash_cents','cycle','acquired']})
write(HERE/'summary.json',result);print(json.dumps(result,indent=2))
