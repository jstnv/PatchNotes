from pathlib import Path
import json
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v9/project';BASE=Path(__file__).parent
def edit(path,old,new,count=1):
 f=P/path;s=f.read_text(encoding='utf-8');assert old in s,(path,old[:45]);f.write_bytes(s.replace(old,new,count).encode())
loader='''## Fixed bundled, source-bound certified states; no career replay on the UI.
extends RefCounted
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const PATHS:=["res://certified/rival-opening-5607-v1.json","res://certified/rival-opening-5613-v1.json"]
var error:=""
func create(player: RunState,catalog: RefCounted) -> RivalWorld:
	if player==null or catalog==null or player.get_completed_run_cycles()!=0 or player._calendar_start_year!=1980 or not player.get_released_game_ids().is_empty():error="Opening requires a fresh1980 Studio";return null
	var index: int=str(player._bank_run_id).sha256_text().substr(0,8).hex_to_int()%PATHS.size()
	var input: Variant=JSON.parse_string(FileAccess.get_file_as_string(PATHS[index]))
	if not input is Dictionary or input.size()!=8 or input.get("format")!="certified-rival-opening-v1" or input.get("source_identity")!=Replay.source_identity() or input.get("rng_algorithm")!=RunRandom.ALGORITHM or input.get("engine_version")!=Engine.get_version_info().string or not input.get("fixture") is Dictionary or not input.get("integrity") is String:error="Opening certificate source/format mismatch";return null
	var body: Dictionary=input.duplicate(true);body.erase("integrity")
	if input.integrity!=Replay.digest(body) or input.fixture.size()!=2 or not input.fixture.get("world") is Dictionary or input.fixture.world.get("source_identity")!=input.source_identity:error="Opening certificate integrity mismatch";return null
	var adapter:=StudioCheckpoint.new();var payload:=adapter.capture(player)
	if payload.is_empty():error=adapter.error;return null
	var codec:=Codec.new();var world:=codec.restore(input.fixture.world,payload,player,catalog)
	if world==null:error=codec.error;return null
	if world.studios.size()!=8 or world.calendar_offsets.size()!=8 or world.policy_states.size()!=8 or world.cycle!=0:error="Incomplete eight-Studio opening";return null
	return world
static func copy_catalog(definitions: RefCounted) -> RefCounted:
	var base: Array[CardData]=[];var extra: Array[CardData]=[]
	for card: CardData in definitions.cards.values():
		var copy:=CardData.new()
		for property: Dictionary in card.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				var field: Variant=card.get(property.name)
				copy.set(property.name,field.duplicate(true) if field is Dictionary or field is Array else field)
		if card in definitions.primitive:base.append(copy)
		else:extra.append(copy)
	return preload("res://scripts/simulation/development_catalog.gd").new(base,extra)
'''
(P/'scripts/market/rival_opening_loader.gd').write_bytes(loader.encode())
edit('scripts/market/rival_trial.gd','static func create_world(player: RunState, catalog: RefCounted) -> RivalWorld:','''static func create_world(player: RunState,catalog: RefCounted) -> RivalWorld:
	return preload("res://scripts/market/rival_opening_loader.gd").new().create(player,catalog)

## Explicit predecessor fixture/recovery utility; existing worlds restore their
## original two owners and policy. New-save creation never silently falls back.
static func create_legacy_world(player: RunState, catalog: RefCounted) -> RivalWorld:''')
# All material opening state participates in runtime identity. Only the circular
# binding/integrity metadata is omitted. Full manifests still hash raw files.
edit('scripts/simulation/development_replay.gd','paths.sort()','paths.sort()',1)
edit('scripts/simulation/development_replay.gd','return JSON.stringify(rows).sha256_text()', '''for opening: String in ["res://certified/rival-opening-5607-v1.json","res://certified/rival-opening-5613-v1.json"]:
		if not FileAccess.file_exists(opening):continue
		var certificate: Variant=JSON.parse_string(FileAccess.get_file_as_string(opening))
		var material: Dictionary=certificate.get("fixture",{}).duplicate(true) if certificate is Dictionary and certificate.get("fixture") is Dictionary else {}
		if material.get("world") is Dictionary:material.world.erase("source_identity")
		rows.append([opening+"@material-v1",var_to_bytes(_canonical_data(material)).hex_encode().sha256_text()])
	return JSON.stringify(rows).sha256_text()''')
f=P/'scripts/simulation/development_replay.gd';s=f.read_text(encoding='utf-8');s+='''
static func _canonical_data(value: Variant) -> Variant:
	if value is Array:
		var result: Array=[]
		for item: Variant in value:result.append(_canonical_data(item))
		return result
	if value is Dictionary:
		var result: Dictionary={};var keys: Array=value.keys();keys.sort()
		for key: Variant in keys:result[key]=_canonical_data(value[key])
		return result
	return value
''';f.write_bytes(s.encode())
edit('scripts/debug/quality_cohort_probe.gd','var result:={"source":Replay.source_identity()', '''if issues.is_empty():
		var certificate:={"format":"certified-rival-opening-v1","source_identity":Replay.source_identity(),"generation_source_identity":Replay.source_identity(),"rng_algorithm":RunRandom.ALGORITHM,"engine_version":Engine.get_version_info().string,"seed":seed,"fixture":fixture}
		certificate.integrity=Replay.digest(certificate)
		FileAccess.open(output+".opening.json",FileAccess.WRITE).store_string(JSON.stringify(certificate,"\\t"))
	var result:={"source":Replay.source_identity()''')
(P/'certified').mkdir(exist_ok=True)
for seed in ['5607','5613']:
 d=json.loads((BASE/f'sims/quality-shared-{seed}-20261030-v8/cohort.json').read_text(encoding='utf-8'))
 assert not d['issues']
 pending={'format':'PENDING-NOT-CERTIFIED','source_identity':d['source'],'generation_source_identity':d['source'],'rng_algorithm':'godot-4.7.1-rng-v1','engine_version':'pending','seed':seed,'fixture':d['fixture']}
 (P/f'certified/rival-opening-{seed}-v1.json').write_text(json.dumps(pending,ensure_ascii=False,indent=2),encoding='utf-8')
if not (P/'export_presets.cfg').exists():
 (P/'export_presets.cfg').write_bytes((Path(__file__).resolve().parents[4]/'patch-notes/export_presets.cfg').read_bytes())
edit('export_presets.cfg','include_filter="data/*.json,','include_filter="certified/*.json,data/*.json,')
edit('export_presets.cfg','script_export_mode=2','script_export_mode=0')
print('Source-bound opening loader + normalized MATERIAL identity; pending assets reject until actual source-matched certification.')
