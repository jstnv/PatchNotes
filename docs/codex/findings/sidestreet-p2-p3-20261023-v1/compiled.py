"""Actual audited Windows executable, external harness, packaged runtime only."""
from pathlib import Path
import json
from acceptance import run,HOME
def main():
    manifest=json.loads((HOME/'export-v4/build-manifest.json').read_text(encoding='utf8'))
    exe=Path(manifest['workspace'])/'demo/Patch Notes Demo.exe'
    run('additional.py','p1_matrix','--tag','compiled-p1_matrix-v2','--exe',exe)
    for width in [1152,1280]:run('native.py','--width',width,'--tag','compiled-'+str(width),'--exe',exe)
    run('additional.py','world','--tag','compiled-world','--exe',exe)
    (HOME/'compiled-result.json').write_text(json.dumps({'pass':True,'exe':str(exe),'release_ready':False},indent=2),encoding='utf8')
if __name__=='__main__':main()
