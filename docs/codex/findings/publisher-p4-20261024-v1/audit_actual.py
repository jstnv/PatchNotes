"""Exact saved-state and original-save audit for direct P4 EXE interaction."""
from pathlib import Path
import hashlib,importlib.util,json,socket
ROOT=Path(__file__).resolve().parents[4]
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
def read(path):return json.loads(path.read_text(encoding='utf8'))
def payload(path):
    envelope=read(path);assert hashlib.sha256(envelope['payload_utf8'].encode()).hexdigest()==envelope['payload_sha256']
    return json.loads(envelope['payload_utf8'])
def without_sequence(value):
    value=json.loads(json.dumps(value));value.pop('sequence',None);return value
def main():
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    actual=HOME/'actual-p4-1152';reference=HOME/'p4-compiled-reference-v1'
    assert read(actual/'cancel-receipt.json')=={'pass':True,'seed_generation_byte_exact':True,'generation_count':1}
    main_process=read(actual/'process.json');main_exit=read(actual/'exit.json')
    assert main_exit['exit']==0 and main_exit['original_fixture_preserved']
    assert sim.sha(Path(main_process['original']))==main_process['original_sha256']==main_exit['source_sha256']
    comparisons=[]
    for stage in ['postsupport','later-sales']:
        left=without_sequence(payload(actual/('actual-'+stage+'.generation.json')))
        right=without_sequence(read(reference/(stage+'.json')))
        top=[key for key in set(left)|set(right) if key!='run' and left.get(key)!=right.get(key)]
        changed=[key for key in set(left['run'])|set(right['run']) if left['run'].get(key)!=right['run'].get(key)]
        assert not top and set(changed)<= {'seen_tutorial_topics','pending_publisher_notifications'},(stage,top,changed)
        comparisons.append({'stage':stage,'exact_gameplay_finance_standing_support_rights_sales_rng':True,'ui_only_differences':changed,'normal_store_sequence_excluded':True})
    final=without_sequence(payload(actual/'actual-later-sales.generation.json'))
    deal=final['run']['support_deals'][0]['value'];rights=final['run']['support_rights'][0]['value']
    assert deal['funding_cents']=='70000' and deal['marketing_points']=='5' and deal['budget_cents']=='87500'
    assert int(rights['publisher_recoup_cents'])>0 and int(rights['studio_earned_cents'])>0
    cold=[]
    for tag,width in [('actual-p4-cold-1152',1152),('actual-p4-cold-1280',1280)]:
        folder=HOME/tag;process=read(folder/'process.json');receipt=read(folder/'exit.json')
        assert receipt['exit']==0 and receipt['original_fixture_preserved'] and read(folder/'preferences-seed.json')['width']==width
        assert sim.sha(Path(process['original']))==process['original_sha256']==receipt['source_sha256']
        saves=Path(process['profile'])/'APPDATA/Godot/app_userdata/Patch Notes Demo/saves/studio'
        latest=max(saves.glob('checkpoint.*.json'),key=lambda p:int(p.name.split('.')[1]))
        assert without_sequence(payload(latest))==final,tag
        cold.append({'tag':tag,'width':width,'all_saved_fields_rng_exact':True,'exit':0})
    assert read(actual/'exit.json')['exit']==0
    for tag in ['actual-p4-1152','actual-p4-cold-1152','actual-p4-cold-1280']:
        text=(HOME/tag/'exe.log').read_text(encoding='utf8',errors='replace')
        assert not any(('SCRIPT ERROR' in line or line.startswith('ERROR:')) and 'root certificate store' not in line for line in text.splitlines()),tag
    original=read(HOME/'safe-close-before.json')['saved_generations']
    for item in original:assert sim.sha(Path(item['file']))==item['sha256']==sim.sha(Path(item['backup']))
    with socket.socket() as lease:lease.bind(('127.0.0.1',62741))
    result={'pass':True,'comparisons':comparisons,'cold':cold,'user_generations_preserved':len(original),'production_writer_released':True,'support':{'funding_cents':70000,'marketing':5,'budget_cents':87500,'rights':rights},'scope':'Direct unmodified release EXE quote/Back/Begin, first-four hand per phase and early launch, one older owned-title campaign, then two cold Continues. Full-success/repeat/cap/world evidence is separately scripted.','release_ready':False}
    sim.write_json(HOME/'p4-actual-closeout.json',result)
    print(json.dumps({'pass':True,'comparisons':len(comparisons),'cold':len(cold),'original_generations':len(original)}),flush=True)
if __name__=='__main__':main()
