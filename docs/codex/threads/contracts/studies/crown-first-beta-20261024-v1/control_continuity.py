from setup import HERE,PREV,RAW,write
import json
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def main():
    a=load(HERE/'analysis.json');old=load(PREV/'analysis.json')
    oldraw=RAW.parent/'crown-beta-redraw-20261024-v1';rows=[]
    for row in a['rows']:
        if row['arm']=='candidate':continue
        priorarm='control' if row['arm']=='control' else 'candidate'
        before=load(oldraw/row['pair']/'cases'/(priorarm+'-'+row['pair'])/'result.json')
        after=load(RAW/row['pair']/'cases'/row['case']/'result.json')
        fields=['initial_state','initial_rng','final_state','final_rng','commands','accepted_commands','final_run_cycle','outcome']
        rows.append({'current':row['case'],'prior':priorarm+'-'+row['pair'],'fields_equal':{k:before[k]==after[k] for k in fields}})
    report={'complete':a['complete'],'same_mechanics':a['identities'][0]['source']==old['identities'][0]['source'],'rows':rows,'note':'Fresh legal recipes were run; prior evidence is not substituted for current cases. Differences, if any, must be interpreted rather than ignored.'}
    write(HERE/'control-continuity.json',report)
    print(json.dumps({'complete':report['complete'],'same_mechanics':report['same_mechanics'],'all_checked_fields_equal':all(all(r['fields_equal'].values()) for r in rows),'cases':len(rows)}))
if __name__=='__main__':main()
