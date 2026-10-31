"""Declared current-source careers, source-matched controls and cold replays."""
from pathlib import Path
import argparse, json, subprocess, sys, time, shutil
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT))
from tools import simulate as sim
GENRES=['action','adventure','role_playing','strategy','simulation','puzzle','sports','racing']
def main():
    p=argparse.ArgumentParser();p.add_argument('--bundle',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--reuse',type=Path);p.add_argument('--minimal-projection',action='store_true');a=p.parse_args()
    bundle=a.bundle.resolve();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False)
    project=bundle/'project';frozen=sim.read_json(bundle/'snapshot-manifest.json');sim.check_snapshot(project,frozen)
    godot=sim.resolve_godot('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe')
    cases=[(g,s,'candidate','trial') for s in ['5607','5613'] for g in GENRES]
    cases += [(g,s,'control','trial') for s in ['5607','5613'] for g in ['action','adventure']]
    cases += [('action','5607','candidate','ordinary')]
    report={'mode':'current-source-independent-careers','canonical_adoption':False,'bundle':str(bundle),'manifest_sha256':sim.sha(bundle/'snapshot-manifest.json'),'seeds':['5607','5613'],'stop_cycle':72,'command_bound':340,'timeout_seconds':240,'cases':[]}
    for genre,seed,profile,finance in cases:
        label=f'{profile}-{finance}-{genre}-{seed}';case=out/label;case.mkdir()
        if a.reuse and label=='candidate-trial-action-5607':
            source=a.reuse.resolve();old=sim.read_json(source/'snapshot-manifest.json')
            relevant=lambda m:{k:v for k,v in m.items() if k.endswith(('.gd','.json','.tscn','.tres')) and not k.startswith('scripts/debug/experiment_policy/')}
            if relevant(old)!=relevant(frozen):raise RuntimeError('Reused smoke source mismatch')
            for path in source.iterdir():
                if path.is_file():shutil.copy2(path,case/path.name)
            result=sim.read_json(case/'prelude.json')
            row={'case_id':label,'genre':genre,'seed':seed,'profile':profile,'finance':finance,'reused_from':str(source),'source_manifest_sha256':sim.sha(source/'snapshot-manifest.json'),'exit':sim.read_json(source/'result.json')['exit'],'cycle':result['final_cycle'],'issue':result['issue'],'release_count':len(result['releases']),'scope':result['final_owned_scope'],'source_identity':result['source_identity'],'tape_saved':result['tape_saved'],'reached72':result['final_cycle']==72 and not result['issue']}
            sim.write_json(case/'case-report.json',row);report['cases'].append(row);sim.write_json(out/'batch-report.json',report);print(json.dumps(row),flush=True);continue
        argv=[str(godot),'--headless','--audio-driver','Dummy','--path',str(project),'--script','res://scripts/debug/one_action_prelude_probe.gd','--quit-after','60','--',f'--seed={seed}',f'--genre={genre}','--policy=audio_path','--standard=midpoint','--stop-cycle=72',f'--profile={profile}',f'--finance={finance}',f'--output={case}/prelude.json',f'--tape={case}/prelude.tape.json']
        if a.minimal_projection:argv.append('--projection=minimal')
        sim.write_json(case/'command.json',{'argv':argv,'timeout_seconds':240});started=time.monotonic()
        row={'case_id':label,'genre':genre,'seed':seed,'profile':profile,'finance':finance}
        try:
            with (case/'godot.log').open('wb') as stream:
                c=subprocess.run(argv,env=sim.isolated_environment(case/'profile'),cwd=case,stdout=stream,stderr=subprocess.STDOUT,timeout=240)
            row.update(exit=c.returncode,seconds=time.monotonic()-started)
            if (case/'prelude.json').is_file():
                result=sim.read_json(case/'prelude.json')
                row.update(cycle=result.get('final_cycle'),issue=result.get('issue'),release_count=len(result.get('releases',[])),scope=result.get('final_owned_scope'),tape_saved=result.get('tape_saved'),source_identity=result.get('source_identity'))
                row['reached72']=c.returncode==0 and result.get('final_cycle')==72 and not result.get('issue')
            else:row['error']='No result artifact'
        except subprocess.TimeoutExpired as e:
            if not (case/'godot.log').exists():(case/'godot.log').write_bytes(e.stdout or b'')
            row.update(error='timeout',seconds=time.monotonic()-started)
        sim.check_snapshot(project,frozen);sim.write_json(case/'case-report.json',row)
        report['cases'].append(row);sim.write_json(out/'batch-report.json',report)
        print(json.dumps(row),flush=True)
    report['completed_candidate_72']=sum(bool(r.get('reached72')) for r in report['cases'] if r['profile']=='candidate' and r['finance']=='trial')
    report['runner_errors']=[r['case_id'] for r in report['cases'] if r.get('error')]
    sim.write_json(out/'batch-report.json',report)
if __name__=='__main__':main()
