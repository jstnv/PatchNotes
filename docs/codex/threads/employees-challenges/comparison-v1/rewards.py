from pathlib import Path
from collections import Counter, defaultdict
import json,statistics

HERE=Path(__file__).resolve().parent
ROOT=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\employees-comparison-20261006/results')

def compact_state(s):
    return {k:s.get(k) for k in ['cycle','cash_cents','redraws','scope','cores','project_cycle']}

def main():
    routes={}; errors=[]; first_pairs=[]
    for spec in json.loads((HERE/'manifest.json').read_text())['jobs']:
        tag='route_'+'_'.join(map(str,spec))
        d=json.loads((ROOT/f'{tag}.json').read_text())
        primary=(d['funding'],d['band'],d['policy'],d['seed'])
        selected=[a for a in d['actions'] if a['phase'] in ['design','alpha']]
        priority=[e for e in d['trial_events'] if e['kind']=='priority' and e['success']]
        curated=[e for e in d['trial_events'] if e['kind']=='redraw' and e['used']]
        uses=Counter(e['game'] for e in priority+curated)
        if any(v>d['staff'] for v in uses.values()): errors.append(dict(route=tag,reason='uses exceed employees per project'))
        successful=[a for a in selected if a.get('committed')]
        for a in successful:
            delta=a['after']['cycle']-a['before']['cycle']
            expected=2 if d['reward']=='paid' and a['priority_use'] else 1
            if delta!=expected: errors.append(dict(route=tag,reason='cycle delta',actual=delta,expected=expected))
            if a['priority_use'] and d['reward']=='bundle' and (not a['matching'] or not a['trained_before']): errors.append(dict(route=tag,reason='bundle qualification'))
        # Refill follows every committed hand. A paid priority can add its own
        # refill; curated consumes the normal redraw before this refill.
        bycycle={int(o['cycle']):compact_state(o['snapshot']) for o in d['finance_observations']}
        for a in d['actions']:
            if 'after' in a: bycycle[int(a['after']['cycle'])]=compact_state(a['after'])
        value=dict(tag=tag,key=list(primary),reward=d['reward'],staff=d['staff'],valid=d['valid'],stop=d['stop'],
            releases=[{k:r[k] for k in ['cycle','final_review','scope','cash_cents','month_1_units','projected_net_cents']} for r in d['releases']],
            final=compact_state(d['final']),low=min([d['initial']['cash_cents']]+[a.get('after',{}).get('cash_cents',d['initial']['cash_cents']) for a in d['actions']]),
            matching_design_hands=sum(a['phase']=='design' and a.get('matching') for a in successful),
            qualifying_projects=sorted({a['game'] for a in successful if a['phase']=='design' and a.get('matching')}),
            training=[{k:e[k] for k in ['game','cycle','staff','selected']} for e in d['trial_events'] if e['kind']=='training'],
            priority_uses=[dict(game=e['game'],cycle=e['before']['cycle'],old=e['old'],new=e['new'],selected=e['selected'],before=compact_state(e['before']),after=compact_state(e['after'])) for e in priority],
            curated_uses=[dict(game=e['game'],cycle=e['before']['cycle'],first=e['first'],second=e['second'],choice=e['choice'],first_value=e['first_value'],chosen_value=e['chosen_value']) for e in curated],
            opportunities=sum(a.get('priority_opportunity',False) for a in selected),
            redraws_used=sum(len([r for r in a.get('redraws',[]) if r['success']]) for a in d['actions']),
            no_redraw_hands=sum(a['before']['redraws']==0 for a in selected),
            common={str(c):bycycle[c] for c in [12,14,18,24,36,48] if c in bycycle})
        routes[tag]=value
        if d['reward']=='bundle' and d['staff']==1 and priority:
            first=priority[0]; action=next(a for a in selected if a['priority_use'])
            baseline_tag='route_'+'_'.join(map(str,(*primary,'none',0)))
            baseline=json.loads((ROOT/f'{baseline_tag}.json').read_text())
            control=next((a for a in baseline['actions'] if a['phase']==action['phase'] and a.get('before',{}).get('cycle')==action['before']['cycle']),None)
            paired=control is not None and control.get('selected')==action['selected'] and control.get('draw')==action['draw']
            same_core=paired and [x-y for x,y in zip(control['after']['cores'],control['before']['cores'])]==[x-y for x,y in zip(action['after']['cores'],action['before']['cores'])]
            first_pairs.append(dict(route=tag,cycle=action['before']['cycle'],selected=action['selected'],same_visible_hand_and_selection=paired,same_immediate_core_gain=same_core,bundle_cycle_delta=action['after']['cycle']-action['before']['cycle'],bank_before=action['before']['redraws'],bank_after=action['after']['redraws'],redraw_count=len(action['redraws'])))
    summaries={}
    for reward in ['paid','standalone','bundle','curated']:
        values=[v for v in routes.values() if v['reward']==reward and v['staff']==1 and v['key'][0]=='base']
        changes=defaultdict(list); better=Counter()
        for v in values:
            base=routes['route_'+'_'.join(map(str,(*v['key'],'none',0)))]
            for game in [1,2,3]:
                if len(v['releases'])>=game and len(base['releases'])>=game:
                    diff=round(v['releases'][game-1]['final_review']-base['releases'][game-1]['final_review'],4)
                    changes[f'game{game}_review'].append(diff); better[f'game{game}_better']+=diff>0; better[f'game{game}_worse']+=diff<0
            for c in ['24','36','48']:
                if c in v['common'] and c in base['common']: changes[f'cycle{c}_cash'].append(v['common'][c]['cash_cents']-base['common'][c]['cash_cents'])
        summaries[reward]=dict(routes=len(values),uses=sum(len(v['priority_uses'])+len(v['curated_uses']) for v in values),
            improved_curated=sum(e['chosen_value']>e['first_value'] for v in values for e in v['curated_uses']),
            full_horizon=sum(len(v['releases'])==3 and 'follow-up actions' in v['stop'] for v in values),better=dict(better),
            changes={k:dict(n=len(a),min=min(a),median=statistics.median(a),max=max(a)) for k,a in changes.items()})
    output=dict(routes=routes,summaries=summaries,first_action_pairs=first_pairs,errors=errors)
    (HERE/'reward-summary.json').write_text(json.dumps(output,indent=2))
    assert not errors,errors
    print(json.dumps(dict(summaries=summaries,first_pairs=first_pairs,errors=errors),indent=2))

if __name__=='__main__':main()
