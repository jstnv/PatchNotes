from pathlib import Path
import hashlib,json,struct
out=Path(__file__).resolve().parent;m=json.loads((out/'build-manifest.json').read_text(encoding='utf-8'));artifact=Path(m['artifact'])
data=(artifact/'Patch Notes v0.03.pck').read_bytes()
magic,version,major,minor,patch,flags,base,directory=struct.unpack_from('<6I2Q',data)
assert (magic,version,major,minor,patch,flags)==(0x43504447,4,4,7,1,2)
count,=struct.unpack_from('<I',data,directory);pos=directory+4;files={}
for _ in range(count):
    n,=struct.unpack_from('<I',data,pos);pos+=4;name='res://'+data[pos:pos+n].rstrip(b'\0').decode('utf-8').removeprefix('res://');pos+=n
    offset,size=struct.unpack_from('<QQ',data,pos);pos+=16;md5=data[pos:pos+16];pos+=16;item_flags,=struct.unpack_from('<I',data,pos);pos+=4
    payload=data[base+offset:base+offset+size]
    assert item_flags==0 and len(payload)==size and hashlib.md5(payload).digest()==md5,name
    files[name]={'bytes':size,'sha256':hashlib.sha256(payload).hexdigest()}
    if name=='res://project.binary':assert payload.startswith(b'ECFG')
    assert not any(p in name.split('/') for p in ['analysis','design-logs','debug','builds','.codex-godot-temp']),name
    assert not name.endswith(('.md','.py','.zip','.txt')),name
    assert name.removeprefix('res://').startswith(('scripts/','scenes/','assets/','data/','resources/','autoload/','queries/','certified/','.godot/')) or name in ['res://icon.svg','res://icon.svg.import','res://project.binary'],name
assert 'res://project.binary' in files
for name,sha in m['included'].items():
    if name.endswith('.uid') or name in ['project.godot','export_presets.cfg']:continue
    assert any('res://'+name+suffix in files for suffix in ['', '.remap','.import']),name
    if name.endswith(('.gd','.json')) and 'res://'+name in files:assert files['res://'+name]['sha256']==sha,name
exe=(artifact/'Patch Notes v0.03.exe').read_bytes();ico=(Path(m['project'])/'assets/branding/patch_notes_paper.ico').read_bytes()
reserved,kind,icons=struct.unpack_from('<HHH',ico);assert reserved==0 and kind==1
for i in range(icons):
    *_,size,offset=struct.unpack_from('<BBBBHHII',ico,6+16*i)
    assert ico[offset:offset+size] in exe,('Missing native icon image',i)
result={'count':count,'all_payload_md5_valid':True,'runtime_scripts_and_json_match_source':True,'excluded_material_absent':True,'native_paper_icon_images':icons,'files':files}
(out/'pack-manifest-verified.json').write_text(json.dumps(result,indent=2),encoding='utf-8',newline='\n')
print('PCK PASS',count,'entries; exact scripts/data; all payload hashes; native paper icon',icons)
