"""Audit actual EXE receipts, source fence, exact reference/cold state and saves."""
from pathlib import Path
import importlib.util,json,shutil,socket,subprocess
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
def read(path):return json.loads(path.read_text(encoding='utf8'))
def payload(path):return json.loads(read(path)['payload_utf8'])
def without_sequence(value):
    value=json.loads(json.dumps(value));value.pop('sequence',None);return value
def main():
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    build=read(HOME/'p2-p3-export/build-manifest.json');package=read(HOME/'p2-p3-export/pack-manifest-verified.json')
    source=sim.source_hashes(ROOT/'patch-notes');assert source==read(HOME/'p2-p3-export/source.json')
    assert all(sim.sha(ROOT/'patch-notes'/path)==sha for path,sha in build['included'].items())
    for name,meta in build['artifacts'].items():assert sim.sha(Path(build['workspace'])/'demo'/name)==meta['sha256']
    assert package['all_payload_md5_valid'] and not package['missing_runtime_files'] and not package['unexpected_files']
    for label in ['clean-import','export-release','headless-startup','graphical-startup']:
        check=read(HOME/'p2-p3-export'/(label+'.command.json'));assert check['exit']==0 and not check['errors']
    for tag in ['p2-p3-route-v2','p2-p3-short-names-v2','p2-p3-later-campaign-v2']:
        result=read(HOME/tag/'result.json');assert result['pass'] and result['exact_replay']
    actual=HOME/'actual-exe-1152'
    reference=HOME/'p2-p3-later-campaign-v2'
    comparisons=[]
    for label,step in [('prequote',86),('postcommission',115),('later-sales',116)]:
        left=without_sequence(payload(actual/f'actual-{label}.generation.json'))
        right=without_sequence(read(reference/f'step-{step}.json'))
        top={key for key in set(left)|set(right) if left.get(key)!=right.get(key) and key!='run'}
        run={key for key in set(left['run'])|set(right['run']) if left['run'].get(key)!=right['run'].get(key)}
        assert not top and run=={'seen_tutorial_topics','pending_publisher_notifications'},(label,top,run)
        comparisons.append({'stage':label,'pass':True,'exact_gameplay_finance_standing_rights_sales_rng':True,'ui_only_differences':sorted(run),'normal_generation_sequence_excluded':True})
    final=without_sequence(payload(actual/'actual-later-sales.generation.json'))
    deal=final['run']['commission_deals'][0]['value']
    assert deal['result']['fee_paid_cents']=='600000' and deal['result']['review_tenths']=='86' and deal['result']['delivery_bp']=='10000'
    report=read(reference/'commission-report.json')
    assert report['units']==492 and report['owner']=='publisher' and report['studio_net_cents']==report['studio_settled_cents']==0
    cold=[]
    for tag,width in [('actual-cold-1152',1152),('actual-cold-1280',1280)]:
        folder=HOME/tag;process=read(folder/'process.json');exit=read(folder/'exit.json');settings=read(folder/'preferences-seed.json')
        assert exit['exit']==0 and exit['original_fixture_preserved'] and settings['width']==width
        saves=Path(process['profile'])/'APPDATA/Godot/app_userdata/Patch Notes Demo/saves/studio'
        latest=max(saves.glob('checkpoint.*.json'),key=lambda p:int(p.name.split('.')[1]))
        assert without_sequence(payload(latest))==final
        assert sim.sha(Path(process['original']))==process['original_sha256']==exit['source_sha256']
        cold.append({'tag':tag,'width':width,'all_saved_fields_rng_exact':True,'generation':latest.name,'exit':0})
    assert read(actual/'exit.json')['exit']==0
    original=read(HOME/'safe-close-before.json')['saved_generations']
    for item in original:assert sim.sha(Path(item['file']))==item['sha256']==sim.sha(Path(item['backup']))
    with socket.socket() as lease:lease.bind(('127.0.0.1',62741))
    for tag in ['actual-exe-1152','actual-cold-1152','actual-cold-1280']:
        text=(HOME/tag/'exe.log').read_text(encoding='utf8',errors='replace')
        assert not any(('SCRIPT ERROR' in line or line.startswith('ERROR:')) and 'root certificate store' not in line for line in text.splitlines()),tag
    result={'pass':True,'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'editor_source':'d4065bc10fd797b32405c507044bc2349b339c2d2a5b2a5c414817d17bc398d9','compiled_source':read(reference/'result.json')['source'],'package_entries':package['count'],'artifacts':build['artifacts'],'preset':build['selected_current_windows_preset'],'actual_route':{'initial':'three releases, cycle33, R19.37','brief':'two legal hands; R29.37 at cycle35','research':'Maps/Sprites/General Combat; Scope30 pool, cycle38, cash498425','commission':'live5 Design/7 Alpha/6 Beta, Review8.6, fullScope30, fee600000 once, R44.37/I15','later_sales':'one legal campaign on owned project3; cycle58, cash570599, commission492 raw units/344055 raw net; Studio entitlement0','names':'commission s; physical-key input, helper Unicode insertion ignored','no_gameplay_injection':True,'size_scope':'Brief/quote/cancel at1152; same setup resized to1280 for live development/release; restored summary and later sales at1152, finance at1280; cold Main Menu Continue at both. Not two entire duplicate playthroughs.'},'comparisons':comparisons,'cold':cold,'user_generations_preserved':len(original),'production_writer_released':True,'limits':['Human comprehension, final balance, audio/device and clean-machine acceptance remain separate.','Current canonical runtime is byte-matched to the new build; existing prior P2/P3 full/cap/repeat/world evidence retains its own source boundary.','P4 mechanics not yet implemented.'],'release_ready':False}
    sim.write_json(HERE/'verification.json',result);sim.write_json(HERE/'source.json',source)
    files={}
    tags=['p2-p3-export','p2-p3-route','p2-p3-route-v2','p2-p3-short-names','p2-p3-short-names-v2','p2-p3-later-campaign','p2-p3-later-campaign-v2','actual-exe-1152','actual-cold-1152','actual-cold-1280']
    for tag in tags:
        for path in (HOME/tag).iterdir():
            if path.is_file() and path.suffix in {'.json','.log','.gd','.png','.py'}:files[path.relative_to(HOME).as_posix()]={'bytes':path.stat().st_size,'sha256':sim.sha(path)}
    sim.write_json(HERE/'external-artifacts.json',{'root':str(HOME),'files':files})
    for tag,leaf in [('actual-exe-1152','brief-r20-result-1152.png'),('actual-exe-1152','commission-quote-1280.png'),('actual-exe-1152','commission-later-sales-1280.png'),('actual-cold-1152','commission-summary-1152.png'),('actual-cold-1280','publisher-receipt-finance-1280.png')]:shutil.copy2(HOME/tag/leaf,HERE/leaf)
    print(json.dumps({'pass':True,'package_entries':package['count'],'comparisons':len(comparisons),'cold':len(cold),'user_generations_preserved':len(original)}))
if __name__=='__main__':main()
