"""Verify final retained results and assemble a source-pinned review record."""
from pathlib import Path
import json,sys,hashlib,difflib,zipfile
ROOT=Path(__file__).resolve().parents[4];THREAD=Path(__file__).resolve().parent;SIMS=THREAD/'sims'
sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as variant
SOURCE='6a9e30f4ff728603230b698f73e9a06dc801b391cde6633187556fc4e5e38405'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    project=THREAD/'simulators/rival-founder-current-20261030-v4'
    metadata,base,candidate,integrity=variant.load_variant(project)
    careers=SIMS/'current-founder-careers-20261030-v4';analysis=read(careers/'analysis.json')
    assert analysis['all_declared_cases_present'] and analysis['candidate_72_count']==16
    positive=[c for c in analysis['cases'] if c['profile']=='candidate' and c['finance']=='trial']
    assert len(positive)==16 and all(c['all_full_scope'] and c['all_zero_bugs'] and c['all_commands_accepted'] and c['final_scope']>=35 and c['phase']!='studio' and c['source_identity']==SOURCE for c in positive)
    assert all(c['projection'].get('admitted') and c['projection'].get('world_captured') for c in positive)
    smoke=SIMS/'current-founder-public-smoke-20261030-v4'
    assert read(smoke/'run-report.json')['ok']
    assert read(SIMS/'current-founder-public-replay-20261030-v4/run-report.json')['ok']
    guards=read(SIMS/'current-founder-final-guards-20261030-v4/guard.json')
    assert all(guards[k] for k in ['normal_restored','future_historical_rejected','wrong_prelude_begin_rejected','c24_capture','source_matched'])
    assert not read(SIMS/'current-founder-profile-final-20261030-v4/rosters.json')['failures']
    assert read(SIMS/'current-visible-guard-green-20261030-v4/result.json')['exit']==0
    worlds={}
    for seed in ['5607','5613']:
        folder=SIMS/f'current-cohort-{seed}-20261030-v4';world=read(folder/'world.json')
        cold=read(SIMS/f'current-cohort-cold-{seed}-20261030-v4/cold.json')
        assert not world['failures'] and not cold['failures'] and cold['actual_digest']==cold['expected_digest']
        assert world['source_identity']==SOURCE and len(world['c0']['studios'])==8 and world['c12']['cycle']==12 and world['market']['ok']
        worlds[seed]={'archive_count':sum(map(len,world['c0']['historical_archive'].values())),'live_c12':len(world['c12']['live_releases']),'market_rows_c12':len(world['market']['rows']),'timings':world['timings'],'save_bytes':world['save_bytes'],'cycle_ms':[r['elapsed_ms'] for r in world['boundaries']],'cold_exact':True}
    replays={}
    for genre,seed in [('simulation','5607'),('adventure','5613')]:
        p=SIMS/f'current-founder-replay-{genre}-{seed}-20261030-v4/replay.json';v=read(p)
        assert v['replay']['ok'] and v['source_identity']==SOURCE
        replays[genre+'-'+seed]={'steps':len(v['replay']['steps']),'sha256':sha(p)}
    canonical=variant.sim.source_hashes(ROOT/'patch-notes')
    meaningful=lambda x:{k:v for k,v in x.items() if not k.endswith(('.uid','.import'))}
    assert meaningful(base)==meaningful(canonical),'Unreconciled canonical semantic drift'
    changes=variant.delta(base,candidate)
    output=SIMS/'current-founder-final-review-20261030-v4';output.mkdir(exist_ok=False)
    diffs=[]
    with zipfile.ZipFile(project/'base-source.zip') as z:
        for row in changes:
            path=row['path']
            if not path.endswith(('.gd','.json','.tscn','.tres')):continue
            before=z.read(path).decode('utf-8-sig').splitlines(True) if path in base else []
            after=(project/'project'/path).read_text(encoding='utf-8-sig').splitlines(True) if path in candidate else []
            diffs+=list(difflib.unified_diff(before,after,fromfile='baseline/'+path,tofile='candidate/'+path))
    (output/'candidate.diff').write_bytes(''.join(diffs).encode())
    final={'source_identity':SOURCE,'candidate_manifest_identity':variant.identity(candidate),'baseline_identity':metadata['base_identity'],'canonical_semantics_unchanged':True,'canonical_metadata_drift':variant.delta(base,canonical),'changed_files':changes,'worlds':worlds,'replays':replays,'case_summary':analysis['seeds'],'candidate_careers_pass':16,'canonical_adoption':False}
    variant.sim.write_json(output/'assessment.json',final)
    # Hash direct result artifacts, never recurse into cached projects/profiles.
    records={}
    folders=[careers]+[p for p in SIMS.iterdir() if p.is_dir() and ('20261030-v4' in p.name or p.name=='current-founder-v4-action-smoke') and p!=output and p!=smoke]
    for folder in folders:
        for p in folder.glob('*'):
            if p.is_file():records[str(p.relative_to(ROOT))]={'sha256':sha(p),'bytes':p.stat().st_size}
        if folder==careers:
            for p in folder.glob('*/*'):
                if p.is_file():records[str(p.relative_to(ROOT))]={'sha256':sha(p),'bytes':p.stat().st_size}
    variant.sim.write_json(output/'evidence-manifest.json',records)
    variant.sim.write_json(smoke/'supplemental-evidence.json',{'assessment':str((output/'assessment.json').relative_to(ROOT)),'assessment_sha256':sha(output/'assessment.json'),'manifest':str((output/'evidence-manifest.json').relative_to(ROOT)),'manifest_sha256':sha(output/'evidence-manifest.json'),'preserve_all_referenced_artifacts':True})
    finding=THREAD/'2026-10-30-current-founder-candidate-findings-v1.md'
    text=finding.read_text(encoding='utf-8').replace('**IN PROGRESS: final v4 regeneration. Canonical adoption HELD; no release approval.**','**CANDIDATE IMPLEMENTATION AND BOUNDED FUNCTIONAL CHECKS COMPLETE. Canonical adoption HELD; quality/funding and remaining acceptance are FAIL/OPEN.**')
    text=text.replace('Final v4 matrix, evidence manifest, packet and session log are appended at closeout.','''## Final v4 closeout

The complete [21-case matrix](sims/current-founder-careers-20261030-v4/analysis.json) regenerates all16 successful72-cycle careers under the corrected guard:63 actual full-Scope, zero-Bug historical games,35 future Scope per Studio, and unchanged8/0 historical8+ counts. Four14-Scope controls block at28; ordinary financing still blocks at c14. No failed case was resampled or relabelled.

The [standard CLI run](sims/current-founder-public-smoke-20261030-v4/run-report.json) completes27 accepted commands /one release; its [fresh27-command/28-sample replay](sims/current-founder-public-replay-20261030-v4/run-report.json) passes. Independent Simulation5607 and Adventure5613 prelude replays pass128/122 commands. Both final eight-owner worlds and their fresh c0→c12 continuations pass all checks, including exact finance/history/RNG and frozen old sales. Source6a9e also passes the actual visible-only exhaustion corner, future/shifted historical-source rejection, c24 capture, all-eight profile round trips and player12-Scope/unknown-profile checks.

[Final source/diff/metrics assessment](sims/current-founder-final-review-20261030-v4/assessment.json) and [hashed artifact index](sims/current-founder-final-review-20261030-v4/evidence-manifest.json) pin every final result. These are bounded functional and sampling results, not canonical migration, live/headless graphical parity, final balance or release readiness. The v3 worst-case loaded timings remain preserved; final v4 timing samples follow below. A changed guard and test harness are not evidence of a performance optimization.

The [sealed review packet](handoffs/current-founder-20261030-v4-review/HANDOFF.md) contains the exact candidate delta and baseline ancestry; it is review-only, not a queued canonical adoption. [Dated implementation log](../../logs/2026-10-30-rival-founder-candidate-v1.md).''')
    text+='\n\n### Final v4 headless timing samples\n\n'
    for seed,w in worlds.items():
        text+=f"Seed{seed}: owner hydration {w['timings']['owner_restore_ms']:.1f}ms; c0 capture {w['timings']['capture_c0_ms']:.1f}ms; c12 restore {w['timings']['restore_c12_ms']:.1f}ms; productive world boundaries {min(w['cycle_ms']):.1f}–{max(w['cycle_ms']):.1f}ms; encoded c0 {w['save_bytes']} bytes.\n\n"
    text+='Hardware/load were not controlled between v3 and v4. Native Research/input and extended late-save acceptance remain NOT RUN/OPEN; no no-lag claim or threshold increase is made.\n'
    finding.write_bytes(text.encode())
    print(json.dumps({'source':SOURCE,'worlds':worlds,'replay_steps':replays,'canonical_semantics_unchanged':True,'assessment':str(output)}))
if __name__=='__main__':main()
