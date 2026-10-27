"""Download authentic upstream TTFs and OFL licenses at exact commits."""
from pathlib import Path
import hashlib,json,urllib.request
ROOT=Path(__file__).resolve().parents[4]
BASE=ROOT/'patch-notes/assets/fonts'
MANIFEST={}
for family,requested in {
    'chakrapetch':['ChakraPetch-Bold.ttf','ChakraPetch-SemiBold.ttf','ChakraPetch-Medium.ttf'],
    'ibmplexsans':None,
    'ibmplexmono':['IBMPlexMono-Regular.ttf'],
}.items():
    def fetch(url):
        request=urllib.request.Request(url,headers={'User-Agent':'PatchNotes-font-provenance'})
        with urllib.request.urlopen(request,timeout=30) as response:return response.read()
    commits=json.loads(fetch('https://api.github.com/repos/google/fonts/commits?path=ofl/'+family+'&per_page=1'))
    commit=commits[0]['sha']
    listing=json.loads(fetch('https://api.github.com/repos/google/fonts/contents/ofl/'+family+'?ref='+commit))
    names={entry['name'] for entry in listing}
    if requested is None:
        requested=['IBMPlexSans-Regular.ttf'] if 'IBMPlexSans-Regular.ttf' in names else [next(n for n in names if n.endswith('.ttf') and 'Italic' not in n)]
    dest=BASE/family;dest.mkdir(parents=True,exist_ok=True)
    records=[]
    for name in requested+['OFL.txt']:
        assert name in names,(family,name,sorted(names))
        url='https://raw.githubusercontent.com/google/fonts/'+commit+'/ofl/'+family+'/'+urllib.parse.quote(name)
        data=fetch(url)
        if name.endswith('.ttf'):assert data[:4] in [b'\x00\x01\x00\x00',b'OTTO']
        else:assert b'SIL OPEN FONT LICENSE' in data.upper()
        target=dest/name
        assert not target.exists(),target
        target.write_bytes(data)
        records.append({'file':name,'url':url,'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data)})
    MANIFEST[family]={'commit':commit,'files':records,'license':(dest/'OFL.txt').read_text(encoding='utf8')}
    print(family,commit,[r['file'] for r in records],flush=True)
(BASE/'LICENSES.json').write_text(json.dumps(MANIFEST,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
