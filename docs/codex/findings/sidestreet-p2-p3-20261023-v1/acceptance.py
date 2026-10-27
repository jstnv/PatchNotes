"""Serial final-source acceptance, concurrent only with one campaign engine."""
from pathlib import Path
import argparse,json,subprocess,sys
HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
def run(script,*args):
    print('ACCEPTANCE',script,*map(str,args),flush=True)
    outcome=subprocess.run([sys.executable,'-X','utf8',str(HERE/script),*map(str,args)])
    if outcome.returncode:raise SystemExit(outcome.returncode)
def main():
    p=argparse.ArgumentParser();p.add_argument('--resume-world',action='store_true');p.add_argument('--after-native1152',action='store_true');a=p.parse_args()
    if not a.resume_world and not a.after_native1152:
        for mode in ['transactions','boundaries','p1_matrix']:run('additional.py',mode,'--tag',mode+'-final')
    else:
        for mode in ['transactions','boundaries','p1_matrix']:
            assert json.loads((HOME/(mode+'-final')/'result.json').read_text(encoding='utf8'))['failures']==0
    if not a.after_native1152:
        run('additional.py','world','--tag','world-final-v2')
        run('native.py','--width',1152,'--tag','native-1152')
    else:
        for tag in ['world-final-v2','native-1152-v3']:assert json.loads((HOME/tag/'result.json').read_text(encoding='utf8'))['failures']==0
    run('native.py','--width',1280,'--tag','native-1280')
    run('focused.py','--tag','focused-ui','--tests','verify_how_to_play','verify_market_browser','verify_market_release_index','verify_rival_world_foundation','verify_rival_gameplay_activation','verify_rival_gameplay_cold_continue','verify_checkpoint_codec','verify_checkpoint_store')
    run('export.py')
    manifest=json.loads((HOME/'export/build-manifest.json').read_text(encoding='utf8'))
    exe=Path(manifest['workspace'])/'demo/Patch Notes Demo.exe'
    for width in [1152,1280]:run('native.py','--width',width,'--tag','compiled-'+str(width),'--exe',exe)
    for mode in ['p1_matrix','world']:run('additional.py',mode,'--tag','compiled-'+mode,'--exe',exe)
    (HOME/'acceptance-result.json').write_text(json.dumps({'pass':True,'exe':str(exe),'release_ready':False},indent=2),encoding='utf8')
if __name__=='__main__':main()
