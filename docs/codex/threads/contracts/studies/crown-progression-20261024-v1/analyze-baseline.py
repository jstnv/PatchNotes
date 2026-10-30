"""Inspect frozen runner artifacts; never loads or mutates gameplay/player saves."""
from pathlib import Path
import hashlib
import json
import shutil

study = Path(__file__).resolve().parent
paths = json.loads((study/'runtime-paths-v2.json').read_text(encoding='utf-8'))
run, replay = Path(paths['run']), Path(paths['replay'])
case = run/'cases/action-cult-4417-current-crown'
load = lambda path: json.loads(path.read_text(encoding='utf-8'))
report, result = load(run/'run-report.json'), load(case/'result.json')
replayed, checkpoint = load(replay/'replay-report.json'), load(case/'studio_checkpoint.json')
out = result['outcome']; state = checkpoint['studio_payload']['run']
offers = {row['key']:row['value'] for row in state['publisher_offers']}
crown = [offer for offer in offers.values() if offer['publisher_id']=='crown_quill']
assert report['ok'] and result['ok'] and replayed['ok']
assert result['status']=='completed' and result['accepted_commands']==result['commands']==85
assert len(replayed['steps'])==85 and all(step['accepted'] for step in replayed['steps'])
assert replayed['final_state']==result['final_state']
assert out['in_studio'] and len(crown)==1
work = crown[0]['state']; earned=work['result']
assert work['paid'] and int(work['hands'])==2
cores = [int(row['value']) for row in work['cores']]
assert cores==[30,18,10,14] and int(earned['numerator'])==int(earned['denominator'])==66
assert int(earned['challenge_grade_bp'])==int(earned['bonus_cash_cents'])==int(earned['bonus_promotion'])==0
assert int(earned['payout'])==192000 and int(earned['promotion'])==12
assert out['finance']['total_overdue_cents']==0
assert state['publisher_relationships']['events']==[]
reviews = [dict(id=x['id'],cycle=x['metadata']['release_cycle'],
                review=x['metadata']['review']['final_review'],
                scope=x['metadata']['review']['scope'],
                required_scope=x['metadata']['review']['required_scope'],
                cores=x['metadata']['review']['cores']) for x in out['releases']]

def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda:handle.read(1024*1024),b''): h.update(chunk)
    return h.hexdigest()

raw = [run/'run-report.json',run/'workspace-source-manifest.json',run/'snapshot-manifest.json',
       case/'result.json',case/'studio_checkpoint.json',case/'replay.tape.json',replay/'replay-report.json']
hashes = {str(p):digest(p) for p in raw}
summary = dict(status='PASS',case=result['case_id'],commands=85,cycle=result['final_run_cycle'],
               releases=reviews,cash_cents=out['cash_cents'],overdue_cents=out['finance']['total_overdue_cents'],
               crown_cash_result=earned,crown_core_half_units=cores,crown_relationship_events=0,
               shadow_candidate_brief_reputation_bp=0,
               shadow_limit='Same cash-work outcome only; no Crown Brief existed or was played.',
               mechanics=result['source_identity'],frozen_source=report['frozen_source_identity'],
               final_state=result['final_state'],runner_sha256=report['runner_sha256'],
               godot_sha256=report['godot_sha256'],policy_sha256=report['policy'],
               exact_replay_steps=85,raw_sha256=hashes,
               analysis_sha256=digest(Path(__file__)))
with (study/'baseline-summary.json').open('x',encoding='utf-8') as handle:
    json.dump(summary,handle,indent=2); handle.write('\n')
for src,name in [(run/'run-report.json','baseline-run-report.json'),(replay/'replay-report.json','baseline-replay-report.json')]:
    assert not (study/name).exists(); shutil.copyfile(src,study/name)
print(json.dumps({k:v for k,v in summary.items() if k not in ['raw_sha256','policy_sha256','crown_cash_result']},indent=2))
