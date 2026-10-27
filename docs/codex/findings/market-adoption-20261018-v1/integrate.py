from pathlib import Path
import zipfile, hashlib, json, re
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
PROJECT=ROOT/'patch-notes'
PACKET=ROOT/'docs/codex/threads/ai-competitors/handoffs/market-density-trial-20261018-v1'

def preserve():
    paths=sorted(PROJECT.glob('scripts/**/*.gd'))+sorted(PROJECT.glob('data/**/*.json'))+sorted(PROJECT.glob('queries/**/*.gd'))
    dest=OUT/'before-source.zip'
    assert not dest.exists()
    hashes={}
    with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED) as archive:
        for p in paths:
            key=p.relative_to(PROJECT).as_posix()
            archive.writestr(key,p.read_bytes());hashes[key]=hashlib.sha256(p.read_bytes()).hexdigest()
    (OUT/'before-source.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')

def apply_candidate(paths, skip_conflicts=False):
    # Apply only exact hunks to inspected files; preserve every unmatched current edit.
    patch=(PACKET/'source-review.patch').read_text(encoding='utf-8')
    for path in paths:
        chunk=patch.split('--- base/'+path+'\n',1)[1].split('--- base/',1)[0]
        p=PROJECT/path
        text=p.read_text(encoding='utf-8') if p.exists() else ''
        for hunk in re.split(r'^@@[^\n]*\n',chunk,flags=re.M)[1:]:
            lines=hunk.splitlines(keepends=True)
            old=''.join(x[1:] for x in lines if x[:1] in [' ','-'])
            new=''.join(x[1:] for x in lines if x[:1] in [' ','+'])
            if not old: text+=new
            else:
                if text.count(old)!=1 and skip_conflicts:
                    print('MANUAL',path,old[:180]);continue
                assert text.count(old)==1,(path,old[:160])
                text=text.replace(old,new,1)
        p.parent.mkdir(parents=True,exist_ok=True)
        p.write_text(text,encoding='utf-8')

if __name__=='__main__':
    preserve()
    apply_candidate([
        'scripts/market/market_transaction_trial.gd','scripts/market/rival_world.gd',
        'scripts/run_state.gd','scripts/project_state.gd',
        'scripts/review/primitive_review_calculator.gd','scripts/simulation/begin_project.gd',
        'scripts/fanbase/studio_fanbase.gd','scripts/sales/released_game_sales.gd',
        'scripts/debug/verify_market_density_trial.gd',
    ])
