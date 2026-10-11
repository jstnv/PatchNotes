"""Preserve exact accepted manifests, including one earlier unrelated test driver."""
from pathlib import Path
import hashlib,json,zipfile,sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
COPY=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/education-source-pin-v1')
def sha(data):return hashlib.sha256(data).hexdigest()
def pin(label,manifest_name):
 manifest=json.loads((HERE/manifest_name).read_text())
 destination=COPY/label
 records=[]
 archive=HERE/('source-'+label+'.zip')
 assert not archive.exists(), 'Use a fresh label; accepted source archives are immutable'
 with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
  for name,expected in manifest.items():
   data=(ROOT/name).read_bytes()
   method='current exact bytes'
   if sha(data)!=expected:
    # The earlier focused run pinned this unrelated restart probe before its
    # first launch revealed an inherited test-member name collision. Reverse
    # only that exact one-line deletion, and accept only the recorded SHA.
    assert name=='patch-notes/scripts/debug/education_restart_probe.gd',name
    before=b'var checks:=0\nfunc verify'
    after=b'var checks:=0\nvar failures:=0\nfunc verify'
    assert data.count(before)==1
    data=data.replace(before,after,1)
    method='exact prior single-line declaration restored; recorded SHA equality required'
   assert sha(data)==expected,(name,sha(data),expected)
   target=destination/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
   assert sha(target.read_bytes())==expected
   info=zipfile.ZipInfo(name,date_time=(2026,10,9,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED
   z.writestr(info,data)
   records.append({'path':name,'sha256':expected,'bytes':len(data),'source':method})
 summary={'manifest':manifest_name,'manifest_sha256':sha((HERE/manifest_name).read_bytes()),'copy':str(destination),'archive':archive.name,'archive_sha256':sha(archive.read_bytes()),'archive_bytes':archive.stat().st_size,'files':len(records),'uncompressed_bytes':sum(r['bytes'] for r in records),'records':records}
 (HERE/('source-'+label+'.json')).write_text(json.dumps(summary,indent=2),encoding='utf8')
 return {k:v for k,v in summary.items() if k!='records'}
if __name__=='__main__':
 print(json.dumps([pin(sys.argv[1],sys.argv[2])] if len(sys.argv)==3 else [pin('current-v1','restart-native_check-v2.source-before.json'),pin('focused-v4','focused-v4.source-before.json')],indent=2))
