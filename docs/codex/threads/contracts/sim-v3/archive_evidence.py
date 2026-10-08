"""Keep portable compressed traces and move large duplicate JSON to the private archive."""
import gzip,json,shutil
from prepare import HERE,ROOT,digest

destination=ROOT/'raw-json'
destination.mkdir(parents=True,exist_ok=True)
moved=[]
for source in sorted(HERE.glob('*.json')):
    if source.stat().st_size<1_000_000:continue
    target=destination/source.name
    assert source.resolve().parent==HERE.resolve() and target.resolve().parent==destination.resolve()
    compressed=source.with_suffix('.json.gz')
    data=source.read_bytes()
    if not compressed.exists():compressed.write_bytes(gzip.compress(data))
    assert gzip.decompress(compressed.read_bytes())==data
    assert not target.exists(),f'Preserve existing archive: {target}'
    moved.append({'file':source.name,'raw_sha256':digest(source),'compressed_sha256':digest(compressed),'archive':str(target)})
    shutil.move(str(source),str(target))
(HERE/'raw-archive.json').write_text(json.dumps(moved,indent=2))
manifest=[{'file':str(p.relative_to(HERE)),'bytes':p.stat().st_size,'sha256':digest(p)} for p in sorted(HERE.rglob('*')) if p.is_file() and '__pycache__' not in p.parts and p.name!='evidence-manifest.json']
(HERE/'evidence-manifest.json').write_text(json.dumps(manifest,indent=2))
print('Archived',len(moved),'duplicate JSON captures; hashed',len(manifest),'portable artifacts.')
