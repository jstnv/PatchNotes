"""Serial real-disk/native Continue matrix; originals are byte-copied only."""
from pathlib import Path
import json
from acceptance import HOME,run as execute,HERE
ROOT=HERE.parents[3]
def read(path):return json.loads(path.read_text(encoding='utf8'))
def run(script,*args):
    args=list(args);index=args.index('--tag')+1;tag=str(args[index]);result=HOME/tag/'result.json'
    if result.is_file():
        prior=read(result)
        if prior.get('pass') is True or prior.get('failures')==0:
            print('RETAIN PASS',tag,flush=True);return
        version=2
        while (HOME/(tag+'-v'+str(version))).exists():
            leaf=HOME/(tag+'-v'+str(version))/'result.json'
            if leaf.is_file() and read(leaf).get('failures')==0:
                print('RETAIN PASS',tag+'-v'+str(version),flush=True);return
            version+=1
        args[index]=tag+'-v'+str(version)
    execute(script,*args)
def main():
    exe=Path(read(HOME/'export-v4/build-manifest.json')['workspace'])/'demo/Patch Notes Demo.exe'
    for mode,tag,name in [('source','native-1152-v3','Patch Notes'),('compiled','compiled-1152-v2','Patch Notes Demo')]:
        extra=['--exe',exe] if mode=='compiled' else []
        saved=HOME/tag/'profile/APPDATA/Godot/app_userdata'/name/'parity/sidestreet-native-1152'
        candidates={}
        before_quote=HOME/'native-1152/profile/APPDATA/Godot/app_userdata/Patch Notes/parity/sidestreet-native-1152' if mode=='source' else HOME/tag/'before-quote'
        for path in [*saved.glob('checkpoint.*.json'),*before_quote.glob('checkpoint.*.json')]:
            payload=json.loads(read(path)['payload_utf8']);n=payload['run'];count=len(n['released_games']);deals=n['commission_deals']
            label='before-quote' if count==4 and not deals else 'full' if count==5 and deals and deals[0]['value']['result'] is not None else 'later-sales' if count==6 and deals else None
            if label:
                sequence=int(path.name.split('.')[1])
                if sequence>candidates.get(label,(0,None))[0]:candidates[label]=(sequence,path)
        assert set(candidates)=={'before-quote','full','later-sales'},candidates
        for label,(_,path) in candidates.items():run('cold.py','--tag','cold-'+mode+'-'+label,'--save',path,*extra)
        for label,stage,case in [('partial','first','maps-control'),('zero','zero','zero-fee')]:
            disk='disk-'+mode+'-'+label
            run('publish_disk.py','--tag',disk,'--fixture',HOME/stage/'cases'/case/'studio_checkpoint.json',*extra)
            path=read(HOME/disk/'result.json')['save']
            for width in ([1152,1280] if mode=='compiled' else [1152]):run('cold.py','--tag','cold-'+mode+'-'+label+'-'+str(width),'--width',width,'--save',path,*extra)
        world_tag='compiled-world' if mode=='compiled' else 'world-operator'
        for label,suffix in [('active','.fixture.json'),('operator','.operator-fixture.json')]:
            disk='disk-world-'+mode+'-'+label
            run('publish_disk.py','--tag',disk,'--fixture',HOME/world_tag/('result.json'+suffix),*extra)
            run('cold.py','--tag','cold-world-'+mode+'-'+label,'--save',read(HOME/disk/'result.json')['save'],*extra)
    old=ROOT/'docs/codex/findings/publisher-p1-20261023-v1'
    for label,folder,name,sequence,extra in [
        ('p1-editor-founder','native-editor-profile','Patch Notes',2,[]),
        ('p1-compiled-founder','native-editor-profile','Patch Notes',2,['--exe',exe]),
        ('p1-compiled-world','native-export-old-profile','Patch Notes Demo',2,['--exe',exe]),
        ('pre-p1-compiled-founder','native-export-founder-profile','Patch Notes Demo',1,['--exe',exe])]:
        run('cold.py','--tag','cold-'+label,'--save',old/folder/'APPDATA/Godot/app_userdata'/name/'saves/studio'/('checkpoint.'+str(sequence)+'.json'),*extra)
    (HOME/'cold-matrix-result.json').write_text(json.dumps({'pass':True,'release_ready':False},indent=2),encoding='utf8')
if __name__=='__main__':main()
