"""Inspect actual Godot 4.7 PCK v4 entries, payload hashes and export allowlist."""
from pathlib import Path
import hashlib,json,struct
OUT=Path(__file__).resolve().parents[1]/'design-logs/task11-windows-export-v1'
m=json.loads((OUT/'build-manifest.json').read_text(encoding='utf-8'))
path=Path(m['workspace'])/'demo/Patch Notes Demo.pck'
data=path.read_bytes()
magic,version,major,minor,patch,flags,base,directory=struct.unpack_from('<6I2Q',data)
assert magic==0x43504447 and version==4 and (major,minor,patch)==(4,7,1) and flags==2
count,=struct.unpack_from('<I',data,directory);pos=directory+4;files={}
for _ in range(count):
 n,=struct.unpack_from('<I',data,pos);pos+=4
 name='res://'+data[pos:pos+n].rstrip(b'\0').decode('utf-8').removeprefix('res://');pos+=n
 offset,size=struct.unpack_from('<QQ',data,pos);pos+=16
 md5=data[pos:pos+16];pos+=16
 item_flags,=struct.unpack_from('<I',data,pos);pos+=4
 assert item_flags==0,(name,item_flags)
 payload=data[base+offset:base+offset+size]
 assert len(payload)==size and hashlib.md5(payload).digest()==md5,name
 files[name]={'bytes':size,'sha256':hashlib.sha256(payload).hexdigest(),'md5_valid':True}
for name in files:
 rel=name.removeprefix('res://')
 assert not any(part in rel.split('/') for part in ['analysis','design-logs','debug','builds','.codex-godot-temp']),name
 assert not rel.endswith(('.md','.py','.zip','.txt')),name
 assert rel.startswith(('scripts/','scenes/','assets/','data/','resources/','.godot/')) or rel in ['icon.svg','icon.svg.import','project.binary'],name
missing=[]
for name in m['included']:
 if name.endswith('.uid') or name in ['project.godot','export_presets.cfg']:continue
 if 'res://'+name not in files and 'res://'+name+'.remap' not in files and 'res://'+name+'.import' not in files:missing.append(name)
assert not missing,missing
result={'pck':str(path),'format':version,'engine':[major,minor,patch],'count':count,'all_payload_md5_valid':True,'missing_runtime_files':missing,'unexpected_files':[],'files':files}
(OUT/'pack-manifest-verified.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print('PCK PASS',count,'entries; all runtime files retained; every payload MD5 verified; excluded material absent')
