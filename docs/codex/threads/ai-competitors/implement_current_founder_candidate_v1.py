"""Reconcile retained prelude seams into the new current-source private variant."""
from pathlib import Path
import json, zipfile, subprocess, sys, difflib

ROOT = Path(__file__).resolve().parents[4]
THREAD = Path(__file__).resolve().parent
OLD = THREAD / 'simulators/rival-eight-cyclezero-audio-store-20261029-v3'
NEW = THREAD / 'simulators/rival-founder-current-20261029-v1'
EVIDENCE = THREAD / 'sims/current-founder-port-20261029-v1b'

def main():
    EVIDENCE.mkdir(exist_ok=False)
    profile = NEW/'project/scripts/market/rival_founder_profile.gd'
    assert not profile.exists(), 'RED: profile must be absent on the canonical baseline'
    (EVIDENCE/'red-profile.txt').write_text('FAIL: explicit rival founder profile missing from current-source baseline. Player roster remains v5.\n')
    # Current Audio/Gameplay and player roster are already authoritative. Do not
    # reapply their older private substitutes or change the global start epoch.
    paths = ['queries/market_release_index.gd','scripts/project_state.gd','scripts/run_state.gd',
             'scripts/fanbase/studio_fanbase.gd','scripts/market/market_transaction_trial.gd',
             'scripts/market/rival_world.gd','scripts/market/rival_world_checkpoint.gd',
             'scripts/persistence/checkpoint_schema.gd','scripts/persistence/studio_checkpoint.gd',
             'scripts/sales/released_game_sales.gd']
    report = []
    with zipfile.ZipFile(OLD/'base-source.zip') as z:
        for rel in paths:
            base=z.read(rel).decode('utf-8-sig').replace('\r\n','\n')
            theirs=(OLD/'project'/rel).read_text(encoding='utf-8-sig')
            ours=(NEW/'project'/rel).read_text(encoding='utf-8-sig')
            # Avoid duplicate already-adopted Audio changes in RunState.
            if rel=='scripts/run_state.gd':
                theirs=theirs.replace('const START_YEAR := 1977 # Private one-rival prelude clock; current Review table is provisional diagnostic input.','const START_YEAR := 1980')
            name=rel.replace('/','__')
            for suffix,content in [('base',base),('ours',ours),('theirs',theirs)]:
                (EVIDENCE/(name+'.'+suffix)).write_text(content,encoding='utf-8')
            argv=['git','merge-file','-p',str(EVIDENCE/(name+'.ours')),str(EVIDENCE/(name+'.base')),str(EVIDENCE/(name+'.theirs'))]
            result=subprocess.run(argv,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            text=result.stdout.decode('utf-8')
            (EVIDENCE/(name+'.merged')).write_text(text,encoding='utf-8')
            report.append({'path':rel,'exit':result.returncode,'stderr':result.stderr.decode()})
            if result.returncode==0: (NEW/'project'/rel).write_text(text,encoding='utf-8')
    (EVIDENCE/'merge-report.json').write_text(json.dumps(report,indent=2))
    for rel in ['scripts/market/historical_standard_trial.gd','scripts/debug/one_action_prelude_probe.gd']:
        target=NEW/'project'/rel
        assert not target.exists() or target.read_bytes()==(OLD/'project'/rel).read_bytes()
        target.write_bytes((OLD/'project'/rel).read_bytes())
    print(json.dumps(report,indent=2))

if __name__=='__main__': main()
