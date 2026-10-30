"""Read the actual canonical checkpoint journal; no generated hand credits."""
from pathlib import Path
import json,hashlib
out=Path(__file__).resolve().parent
path=out/'tail-tier4.json.final.json'
dto=json.loads(path.read_text()); roster=dto['run']['employees']
mapping=lambda rows:{row['key']:row['value'] for row in rows}
staff=mapping(roster['employees'])
manager=next(e for e in staff.values() if e['type']=='project_manager')
courses=mapping(manager['career']['courses']);games=mapping(manager['career']['games'])
rows=[]
for index,(course,data) in enumerate(courses.items()):
    start=int(data['cycle']);end=int(data['completed_cycle']);floor=20-index*5
    facts=[e for e in roster['events'] if e['type']=='career_hand' and start<int(e['cycle'])<=end]
    eligible=[]
    for event in facts:
        beta=event['phase']=='beta';field='beta' if beta else 'primary'
        category=event['cards'][0][field]
        key=category if beta else str(['graphics','sound','technology','design'].index(category)) if category in ['graphics','sound','technology','design'] else ''
        weights=mapping(event['priorities'])
        if all(c[field]==category for c in event['cards']) and int(weights.get(key,-1))==(40-index*5 if beta else floor):eligible.append(event)
    rows.append({'course':course,'enrolled_cycle':start,'completed_cycle':end,'core_floor':floor,'beta_floor':40-index*5,'committed_hands_in_window':len(facts),'minimum_specializations_in_window':len(eligible),'credited_release_ids':games[course],'minimum_specializations_per_credited_game':{game:sum(e['project_id']==game for e in eligible) for game in games[course]}})
report={'fixture':path.name,'fixture_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'funding':'Explicit $3m functional fixture plus $20k legacy helper; no affordability claim','manager_courses':rows,'production_courses':mapping(next(e for e in staff.values() if e['type']=='production')['career']['courses'])}
(out/'actual-career-progress.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
