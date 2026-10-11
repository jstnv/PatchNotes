from pathlib import Path
import hashlib,json,difflib
HERE=Path(__file__).resolve().parent
SOURCE=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-integration-v1-source-copy')
COPY=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/cult-t7-v1-candidate-copy')
changed={}
def edit(name,a,b):
 p=COPY/name;s=p.read_text(encoding='utf8');assert s.count(a)==1,(name,a,s.count(a));p.write_text(s.replace(a,b),encoding='utf8');changed[name]=hashlib.sha256(p.read_bytes()).hexdigest()
(COPY/'scripts/fanbase/cult_candidate.gd').write_text('''class_name CultCandidate
extends RefCounted
## ANALYSIS COPY ONLY. Values are candidate inputs, never approved gameplay.
static func fan_seed() -> int: return int(OS.get_environment("PN_CULT_SEED"))
static func price() -> int: return int(OS.get_environment("PN_CULT_PRICE"))
static func initial(selection: Dictionary) -> int:
\treturn fan_seed() if StudioTraits.is_active(selection, &"cult_following") else 0
''',encoding='utf8')
edit('scripts/studio_traits.gd','version: int = 5','version: int = 6')
edit('scripts/studio_traits.gd','if version not in [3,4,5]','if version not in [3,4,5,6]')
edit('scripts/studio_traits.gd','\tvar refunded :=','\tspent += CultCandidate.price() if version == 6 and seen.has(&"cult_following") else 0\n\tvar refunded :=')
edit('scripts/studio_traits.gd','\tvar remaining :=','\tif version == 6 and seen.has(&"cult_following"): active.append(&"cult_following")\n\tvar remaining :=')
edit('scripts/studio_traits.gd','"effects_mode":&"approved_effects_v1",','"effects_mode":&"analysis_cult_candidate_v1" if version==6 else &"approved_effects_v1",')
edit('scripts/studio_traits.gd','selection.get("effects_mode", &"") == &"approved_effects_v1"','selection.get("effects_mode", &"") in [&"approved_effects_v1", &"analysis_cult_candidate_v1"]')
edit('scripts/run_state.gd','\t_studio_traits = selection.duplicate(true)','\t_studio_traits = selection.duplicate(true)\n\t_fanbase = StudioFanbase.create(CultCandidate.initial(selection))')
edit('scripts/fanbase/studio_fanbase.gd','static func create() -> Dictionary:\n\treturn {"fans": 0,','static func create(initial_seed: int = 0) -> Dictionary:\n\treturn {"initial_seed":initial_seed, "fans": initial_seed,')
edit('scripts/fanbase/studio_fanbase.gd','return {"fans":"uint",','return {"initial_seed":"uint", "fans":"uint",')
edit('scripts/fanbase/studio_fanbase.gd','\tvar rebuilt := create()','\tvar rebuilt := create(state.initial_seed)')
edit('scripts/persistence/studio_checkpoint.gd','\tvar data := rules','\tvar data := rules + "-cult-analysis-v1-%d-%d"%[CultCandidate.fan_seed(),CultCandidate.price()]')
edit('scripts/persistence/studio_checkpoint.gd','\tif not StudioFanbase.validate(r.fanbase,','\tif r.fanbase.initial_seed != CultCandidate.initial(r.studio_traits): return "Invalid analysis seed provenance"\n\tif not StudioFanbase.validate(r.fanbase,')
patch=''
for name in changed:
 patch+=''.join(difflib.unified_diff((SOURCE/name).read_text(encoding='utf8').splitlines(True),(COPY/name).read_text(encoding='utf8').splitlines(True),fromfile='pinned/'+name,tofile='candidate/'+name))
(HERE/'candidate.patch').write_text(patch,encoding='utf8')
for p in (COPY/'scripts/fanbase').glob('cult_candidate.gd'):changed[str(p.relative_to(COPY))]=hashlib.sha256(p.read_bytes()).hexdigest()
(HERE/'candidate-hook-hashes.json').write_text(json.dumps(changed,indent=2),encoding='utf8')
