"""Independent read-only audit of Stage 2's conditional-platform route traces."""
from pathlib import Path
import json

OUT=Path(__file__).resolve().parents[1]/'design-logs/feature-store-staged-v1'
CARDS=['tile_based_backgrounds','color_cycling','parallax_scrolling','custom_key_bindings','sprite_collision_events','local_co_op']
rows=[]
for card in CARDS:
    for fixture in ['none','none_then_compatible']:
        path=OUT/f'stage2_ordinary_{card}_platform_{fixture}.json'
        if not path.exists():continue
        data=json.loads(path.read_text())
        for run in data['rows']:
            assert run['valid'] and not run['errors'], (path,run['case'])
            stages=[a for a in run['actions'] if a.get('phase')=='predevelopment']
            if len(stages)<3:continue
            owned2=card in stages[1]['owned']; owned3=card in stages[2]['owned']
            eligible2=card in stages[1]['project_eligible']; eligible3=card in stages[2]['project_eligible']
            actual={}
            for game in [2,3]:
                actions=[a for a in run['actions'] if a.get('game')==game and a.get('phase') in ['design','alpha']]
                drawn=sum(card in a.get('draw',[]) or card in a.get('final_draw',[]) for a in actions)
                played=sum(a.get('selected',[]).count(card) for a in actions)
                actual[game]={'drawn_hands':drawn,'plays':played}
                if game==2 or fixture=='none': assert drawn==played==0
                assert played<=1
            assert not eligible2
            assert owned2==owned3
            assert eligible3==(owned3 and fixture=='none_then_compatible')
            buys=[p for p in run['trial_purchases'] if p['id']==card and p['bought']]
            assert bool(buys)==owned2
            assert all(p['quote'].get('shadow_platform_compatible') is False for p in buys)
            rows.append(dict(card=card,fixture=fixture,case=run['case'],owned_game2=owned2,owned_game3=owned3,
                eligible_game2=eligible2,eligible_game3=eligible3,game2=actual[2],game3=actual[3]))
summary={}
for card in CARDS:
    summary[card]={}
    for fixture in ['none','none_then_compatible']:
        matches=[r for r in rows if r['card']==card and r['fixture']==fixture]
        summary[card][fixture]=dict(routes=len(matches),purchased=sum(r['owned_game2'] for r in matches),
            game2_eligible=sum(r['eligible_game2'] for r in matches),game2_plays=sum(r['game2']['plays'] for r in matches),
            game3_eligible=sum(r['eligible_game3'] for r in matches),game3_drawn_routes=sum(r['game3']['drawn_hands']>0 for r in matches),
            game3_plays=sum(r['game3']['plays'] for r in matches))
result={'pass':True,'rows_checked':len(rows),'summary':summary,'rows':rows,
    'boundary':'Analysis-only NONE/ALL direct-tag fixture; source RunState subclass filters project supply at creation while owns_feature and persistent owned state remain intact. No live platform selector, per-hardware compatibility matrix or UI warning was tested. A compatible eligible card can remain undrawn or unplayed.'}
(OUT/'stage3_platform_crosscheck_v1.json').write_text(json.dumps(result,indent=2))
print(json.dumps({'pass':True,'rows_checked':len(rows),'summary':summary}),flush=True)
