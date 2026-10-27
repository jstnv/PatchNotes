from pathlib import Path
import difflib,hashlib,json
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
sha=lambda b:hashlib.sha256(b).hexdigest()
paths=['scripts/studio_specialties.gd','scripts/persistence/studio_checkpoint.gd','scripts/market/rival_world_checkpoint.gd','scripts/debug/verify_studio_specialties.gd','scripts/debug/verify_root_first_rosters.gd','scripts/debug/verify_studio_roster_versions.gd','scripts/debug/verify_campaign_live_parity.gd']
files={};patch=[]
for name in paths:
    before=(OUT/'before'/name).read_bytes();after=(ROOT/'patch-notes'/name).read_bytes()
    files[name]={'before_sha256':sha(before),'after_sha256':sha(after)}
    patch.extend(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(OUT/'scoped.patch').write_text(''.join(patch),encoding='utf-8',newline='')
actual=json.loads((OUT/'identity-final.json').read_text())
old=[]
for resource,digest in actual['rows']:
    rel=resource.removeprefix('res://')
    assert sha((ROOT/'patch-notes'/rel).read_bytes())==digest,resource
    previous=OUT/'before'/rel
    old.append([resource,sha(previous.read_bytes()) if previous.is_file() else digest])
identity=lambda rows:sha(json.dumps(rows,ensure_ascii=False,separators=(',',':')).encode())
preceding=json.loads((OUT/'before-pair.json').read_text())['rival_world']['source_identity']
assert identity(old)==preceding
assert identity(actual['rows'])==actual['identity']
fixtures=json.loads((ROOT/'patch-notes/scripts/debug/fixtures/studio_specialties_v4.json').read_text())
assert fixtures==json.loads((OUT/'proposed-rosters-v4.json').read_text())
old_v3=json.loads((ROOT/'patch-notes/scripts/debug/fixtures/studio_specialties_v3.json').read_text())
cards={c['id']:c for c in json.loads((ROOT/'patch-notes/data/card_ledger.json').read_text())}
for genre,row in fixtures.items():
    assert sum(cards[id]['scope'] for id in row['ids'])==row['scope']==12
    assert len(row['ids'])==len(set(row['ids']))==row['count']
    assert set(row['ids'])<set(old_v3[genre]['ids'])
labels=['roots-v2','versions','specialties-v2','native-menu','old-rosters','cold-world','checkpoint','first-games-v2','v4-live-genres','historical-live','rivals']
for label in labels:
    r=json.loads((OUT/(label+'-run.json')).read_text());assert r['exit']==0 and not r['errors'],label
result={'head':'087df09d653858b72c6e2dc344352237433dd3ac','branch':'main','before_source_identity':preceding,'source_identity':actual['identity'],'exact_before_reconstruction':True,'files':files,'new_roster_fixture_sha256':sha((ROOT/'patch-notes/scripts/debug/fixtures/studio_specialties_v4.json').read_bytes()),'all_eight_scope_12':True,'all_strict_subsets_of_v3':True,'passing_labels':labels}
(OUT/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='files'},indent=2))
