from pathlib import Path
import json,re,hashlib,difflib,zipfile
root=Path('.').resolve();out=root/'docs/codex/findings/queue-20261018-v2'
card=json.loads((root/'patch-notes/data/card_ledger.json').read_text(encoding='utf-8-sig'));later=json.loads((root/'patch-notes/data/feature_store_ledger.json').read_text(encoding='utf-8-sig'))
live={x['id']:x for x in card if x.get('type')=='feature' and x.get('phase') in ['design','alpha']};live.update({x['id']:x for x in later})
cat=(root/'patch-notes/scripts/cards/feature_store_catalog.gd').read_text();override=dict(re.findall(r'&"([^"]+)": &"([^"]+)"',cat.split('const PRIMITIVE_PARENTS := {')[1].split('}')[0]))
parents={id:x.get('purchase_parents',[x.get('purchase_parent',override.get(id))] if x.get('purchase_parent',override.get(id)) else []) for id,x in live.items()}
ui=(root/'patch-notes/scripts/ui/feature_store.gd').read_text();lane={}
for title,ids in re.findall(r'&"([^"]+)": \[([^\]]+)\]',ui.split('const LANE_MEMBERS := {')[1].split('}')[0]):
    for id in re.findall(r'&"([^"]+)"',ids):lane[id]=title
rows=['# Live Store graph — source audit, 2026-10-18','', 'Static source reconciliation, not a simulation or candidate adoption. 27 Primitive grants/reserve Features + 15 later Store Features = 42 IDs. All listed parents are live; parent order is authoritative. A granted/previously owned child does not retroactively require its parents.','', '| ID | Lane | Kind | First parent | Second parent | Cross-lane join |','|---|---|---|---|---|---|']
for title in ['Visuals','Audio','Technology & Tools','Gameplay','Story & World']:
    for id in live:
        if lane[id]!=title:continue
        ps=parents[id];cross=any(lane[p]!=title for p in ps)
        rows.append('| `'+id+'` | '+title+' | '+('later' if any(x['id']==id for x in later) else 'Primitive')+' | '+('`'+ps[0]+'`' if ps else 'ROOT')+' | '+('`'+ps[1]+'`' if len(ps)>1 else '—')+' | '+('yes' if cross else 'no')+' |')
def path(target,owned):
    done=set(owned);order=[]
    def visit(id):
        if id in done:return
        for parent in parents[id]:visit(parent)
        done.add(id);order.append(id)
    visit(target);return order
rosters=json.loads((root/'patch-notes/scripts/debug/fixtures/studio_specialties_v2.json').read_text())
rows+=['','## Conditional acquisition routes from all eight v2 starts','','Each cell is the missing IDs in legal parent-first order, stopping at actual granted ownership. After the initial window, admit and finish each listed Feature through paid FIFO Research before admitting its dependent child. Requires available cash at every step; this source review does not assert a funded playthrough, a fastest route, or victory eligibility. No speculative release/era gate is applied to current live Features.','','| Specialty | Cross-lane Character Development milestone role | Difficulty Levels same-tree join |','|---|---|---|']
routes={}
for genre,data in rosters.items():
    paths={target:path(target,set(data['ids'])) for target in ['character_development','difficulty_levels','branching_dialogue','character_classes']};routes[genre]=paths
    rows.append('| '+genre+' | '+' → '.join('`'+x+'`' for x in paths['character_development'])+' | '+' → '.join('`'+x+'`' for x in paths['difficulty_levels'])+' |')
rows+=['','Complete four-target route data: [graph-audit.json](graph-audit.json). These role examples do not select required Innovation milestones. Legacy v1 Strategy/Simulation/Sports retain Maps and lack Levels; Maps satisfies its own ownership test without retroactive Levels. A newly purchased Exploration or other Levels descendant still requires buying Levels.','']
(out/'INNOVATION-GRAPH.md').write_bytes(('\n'.join(rows)).encode())
inputs=['patch-notes/data/card_ledger.json','patch-notes/data/feature_store_ledger.json','patch-notes/scripts/cards/feature_store_catalog.gd','patch-notes/scripts/ui/feature_store.gd','patch-notes/scripts/ui/feature_store_map.gd','patch-notes/scripts/cards/feature_research.gd','patch-notes/scripts/persistence/checkpoint_schema.gd','patch-notes/scripts/legacy/victory_ledger.gd','patch-notes/scripts/legacy/legacy_world.gd','patch-notes/scripts/studio_specialties.gd']
(out/'graph-audit.json').write_text(json.dumps({'inputs':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in inputs},'parents':parents,'lanes':lane,'routes':routes},indent=2))
packet=root/'docs/codex/threads/ai-competitors/handoffs/g4-current-hand-quote-performance-20261018-v1';meta=json.loads((packet/'handoff.json').read_text())
report={'packet':str(packet),'changes':[]}
with zipfile.ZipFile(packet/'base-source.zip') as base,zipfile.ZipFile(packet/'candidate-source.zip') as candidate:
    for row in meta['changes']:
        p=row['path'];b=base.read(p);c=candidate.read(p);now=(root/'patch-notes'/p).read_bytes()
        report['changes'].append({'path':p,'base_verified':hashlib.sha256(b).hexdigest()==row['before_sha256'],'candidate_verified':hashlib.sha256(c).hexdigest()==row['after_sha256'],'current_sha256':hashlib.sha256(now).hexdigest(),'current_equals_base':now==b})
        (out/('ai-drift-'+Path(p).name+'.patch')).write_text(''.join(difflib.unified_diff(b.decode().splitlines(True),now.decode().splitlines(True),fromfile='candidate-base/'+p,tofile='current/'+p)))
(out/'ai-packet-audit.json').write_text(json.dumps(report,indent=2))
print('Graph',len(live),'roots',sum(not x for x in parents.values()),'AI',report['changes'])
