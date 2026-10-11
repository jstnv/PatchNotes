"""Source-pinned private G2 checks. No shared Godot test port or player profile."""
from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[4]
GODOT = Path(r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
BASE = Path(__file__).resolve().parent
BUNDLE = BASE/'sims/g2-legal-mix-v2-prefix'
PROJECT = BUNDLE/'project'
OUT = BASE/'sims/g2-legal-mix-v2-study'

def hashes():
    return {str(p.relative_to(PROJECT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(PROJECT.rglob('*')) if p.is_file() and p.suffix in {'.gd','.json'} and '.godot' not in p.parts}

def run(label, arguments, script='res://scripts/debug/verify_g2_legal_mix.gd'):
    folder = OUT/label
    folder.mkdir()
    env = os.environ.copy()
    for name in ['APPDATA','LOCALAPPDATA']:
        private = folder/'profile'/name.lower()
        private.mkdir(parents=True)
        env[name] = str(private)
    output = folder/'result.json'
    command = [str(GODOT),'--headless','--path',str(PROJECT),'--script',script,'--',*arguments,'--output='+str(output)]
    (folder/'command.json').write_text(json.dumps(command,indent=2))
    started = time.monotonic()
    try:
        result = subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=240)
        log = result.stdout.decode('utf-8',errors='replace')
        code = result.returncode
    except subprocess.TimeoutExpired as exc:
        log = (exc.stdout or b'').decode('utf-8',errors='replace')
        code = -999
    (folder/'godot.log').write_text(log,encoding='utf-8')
    value = json.loads(output.read_text()) if output.exists() else {}
    passed = code == 0 and value.get('ok') is True and 'SCRIPT ERROR' not in log and 'FAIL:' not in log
    errors = [line for line in log.splitlines() if line.startswith('ERROR:') and 'root certificate store' not in line]
    passed = passed and not errors
    row = {'label':label,'passed':passed,'exit_code':code,'elapsed_seconds':time.monotonic()-started,
           'checks':value.get('checks',0),'status':value.get('status'),'errors':errors,'result':str(output)}
    (folder/'process.json').write_text(json.dumps(row,indent=2))
    print(json.dumps(row),flush=True)
    return row,value

def main():
    OUT.mkdir()
    before = hashes()
    rows = []
    unit,_ = run('unit',['--mode=unit'])
    rows.append(unit)
    if not unit['passed']: raise RuntimeError('Candidate unit verifier failed; retain evidence')
    for seed in (4417,90210):
        checkpoint = BUNDLE/f'cases/g2-prefix-{seed}/studio_checkpoint.json'
        for hands in (1,2,3):
            row,value = run(f'baseline-{seed}-{hands}',[f'--checkpoint={checkpoint}','--mode=study',f'--hands={hands}'])
            rows.append(row)
            if not row['passed']: break
            if hands == 1 and value.get('baseline',{}).get('complete'):
                for entry in json.loads((PROJECT/'data/feature_store_ledger.json').read_text()):
                    candidate = entry['id']
                    label = f'store-{seed}-{candidate}'
                    child,result = run(label,[f'--checkpoint={checkpoint}','--mode=study','--hands=1','--candidate='+candidate])
                    rows.append(child)
                    if not child['passed']: break
                    acquisition = result.get('acquisition',{})
                    if acquisition:
                        replay,_ = run(label+'-replay',[f'--checkpoint={checkpoint}','--tape='+acquisition['tape']],
                                       'res://scripts/debug/campaign_replay_cli.gd')
                        rows.append(replay)
    after = hashes()
    summary = {'ok':all(row['passed'] for row in rows) and before == after,'rows':rows,
               'source_unchanged':before == after,'source_hashes':before,
               'scope':'Private candidate; budget deferral is an observed outcome, not a completed ceiling. No gameplay adoption.'}
    (OUT/'summary.json').write_text(json.dumps(summary,indent=2))
    return 0 if summary['ok'] else 1

if __name__ == '__main__':
    raise SystemExit(main())

