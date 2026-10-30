from setup import HERE, write
import json
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))

def main():
    a=load(HERE/'analysis.json');audit=load(HERE/'extra-audit.json');arms={};pairs=[]
    for arm in ['control','extra']:
        rows=[r for r in a['rows'] if r['arm']==arm]
        reviews=[q for r in rows for q in r['review_details']]
        arms[arm]={'cases':len(rows),'complete':sum(r['ok'] for r in rows),'crown_unlocks':sum(r['unlocked'] is True for r in rows),'commands':sum(r['commands'] for r in rows),'accepted':sum(r['accepted_commands'] for r in rows),'releases':sum(r['releases'] for r in rows),'full_scope_releases':sum(q['scope']>=q['required_scope'] for q in reviews),'mean_review':sum(q['final_review'] for q in reviews)/max(1,len(reviews)),'mean_remaining_bugs':sum(q['remaining_bugs'] for q in reviews)/max(1,len(reviews)),'min_cash_cents':min((r['cash_min'] for r in rows),default=None),'max_arrears_cents':max((r['arrears_max'] for r in rows),default=None)}
    for pair in a['pairs']:
        left=next(r for r in a['rows'] if r['pair']==pair['pair'] and r['arm']=='control');right=next(r for r in a['rows'] if r['pair']==pair['pair'] and r['arm']=='extra')
        fields=['case','ok','first_qualifying_release','first_qualifying_cycle','cycle','cash_cents','reviews','zero_variance','costs','acquired']
        pairs.append({'pair':pair['pair'],'control':{k:left[k] for k in fields},'extra':{k:right[k] for k in fields},'last_shared_calendar':pair['calendar'][-1],'additional_hand_count':sum(e['case']==right['case'] for e in audit['extra_hands'])})
    result={'complete':a['complete'] and audit['complete'],'arms':arms,'pairs':pairs,'extra_hand_attempts':len(audit['extra_hands']),'extra_hand_accepted':sum(e['accepted'] for e in audit['extra_hands']),'study_assertions':a['checks'],'extra_assertions':audit['checks'],'controls_reproduced':len(audit['controls_reproduced'])}
    write(HERE/'summary.json',result)
    print(json.dumps(result,indent=2))

if __name__=='__main__':main()
