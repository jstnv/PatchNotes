from setup import HERE,RAW,write
import json,collections,statistics
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))

def main():
    a=load(HERE/'analysis.json');p=load(HERE/'policy-audit.json');p_audit_events=p['reserved_redraws'];arms={};projects=[];cache={}
    for row in a['rows']:
        pair=row['pair'];cid=row['case']
        if pair not in cache:
            ns=collections.defaultdict(list)
            with (RAW/pair/'experiment.log').open(encoding='utf-8-sig') as stream:
                for line in stream:
                    if line.startswith('FOLLOWUP '):
                        n=json.loads(line[9:]);ns[n['case']].append(n)
            cache[pair]=ns
        notes=cache[pair][cid]
        for game in range(1,len(row['review_details'])+1):
            actions=[];fixes=discoveries=0;beta_start=None
            for i,n in enumerate(notes):
                d=n['development'];cmd=n['command']
                if n['releases']+1!=game or cmd['type']!='development' or d['phase']!='beta':continue
                if beta_start is None and d['active']:beta_start={'cycle':n['cycle'],'known':d['known_bugs'],'fixed':d['fixed_bugs'],'core':d['core'],'scope':d['scope']}
                req=cmd['payload']['request']
                if req['type']!='play':continue
                post=notes[i+1]['development'];fixed=post['fixed_bugs']-d['fixed_bugs'];found=post['known_bugs']-d['known_bugs']+fixed
                assert fixed>=0 and found>=0
                fixes+=fixed;discoveries+=found
                selected=[c['definition'] for c in d['candidates'] if c['token'] in req['payload']['candidate_ids']]
                actions.append({'cycle':n['cycle'],'selected':selected,'discovered':found,'fixed':fixed,'extension':n['qa_extra']})
            q=row['review_details'][game-1]
            exit_info=next(e for e in p['beta_exits'] if e['case']==cid and e['release']==game)
            assert fixes==exit_info['fixed_bugs']
            projects.append({'case':cid,'release':game,'beta_entry':beta_start,'beta_hands':actions,'discovered':discoveries,'fixed':fixes,'final_bugs':q['remaining_bugs'],'inferred_total_generated':fixes+q['remaining_bugs'],'review':q['final_review'],'final_exit':exit_info})
    for arm in ['control','reserved','candidate']:
        rows=[r for r in a['rows'] if r['arm']==arm];ids={r['case'] for r in rows}
        releases=[q for r in rows for q in r['review_details']];qas=[q for q in p['qa_extensions'] if q['case'] in ids]
        phases=[x for rec in p['phases'] if rec['case'] in ids for x in rec['phases']]
        arms[arm]={'cases':len(rows),'commands':sum(r['commands'] for r in rows),'releases':len(releases),'crown_access':sum(bool(r['unlocked']) for r in rows),'mean_review':statistics.mean(q['final_review'] for q in releases),'mean_bugs':statistics.mean(q['remaining_bugs'] for q in releases),'full_scope_releases':sum(q['scope']>=q['required_scope'] for q in releases),'qa_extension_hands':len(qas),'extension_discoveries':sum(q['discovered'] for q in qas),'extension_fixes':sum(q['fixed'] for q in qas),'no_effect_extensions':sum(q['discovered']==0 and q['fixed']==0 for q in qas),'beta_redraws':sum(x['redraws'] for x in phases if x['phase']=='beta'),'neutral_market_releases':sum(q['market']['snapshot_id']=='market-0-neutral' and q['market']['recent_count']==0 for q in releases)}
    pairs=[]
    for pair in a['pairs']:
        cmp=load(HERE/(pair['pair']+'-comparison.json'));l,r=[next(x for x in a['rows'] if x['pair']==pair['pair'] and x['arm']==arm) for arm in ['control','candidate']]
        pairs.append({'pair':pair['pair'],'six_release_delta':cmp['matched_release_milestones'][-1]['delta_right_minus_left'],'last_common_calendar':cmp['matched_calendar'][-1],'cash_low_control':l['cash_min'],'cash_low_candidate':r['cash_min'],'rent_delta':r['costs']['rent_paid_cents']-l['costs']['rent_paid_cents']})
    for arm,data in arms.items():
        ps=[p for p in projects if p['case'].startswith(arm+'-')]
        data['no_effect_all_debug_openers']=sum(bool(p['beta_hands']) and set(p['beta_hands'][0]['selected'])=={'debug'} and p['beta_hands'][0]['discovered']==0 and p['beta_hands'][0]['fixed']==0 for p in ps)
        ev=[e for e in p_audit_events if e['case'].startswith(arm+'-')]
        data['redraw_attempts']={timing:{'count':sum(e['timing']==timing for e in ev),'search_hits':sum(e['timing']==timing and e['search_hit'] for e in ev)} for timing in ['first','late']}
    result={'complete':a['complete'] and p['complete'],'study_checks':a['checks'],'policy_checks':p['checks'],'arms':arms,'reserved_attempts':len(p['reserved_redraws']),'reserved_search_hits':sum(e['search_hit'] for e in p['reserved_redraws']),'pairs':pairs,'projects':projects}
    write(HERE/'summary.json',result)
    print(json.dumps({k:v for k,v in result.items() if k not in ['projects','pairs']},indent=2))

if __name__=='__main__':main()
