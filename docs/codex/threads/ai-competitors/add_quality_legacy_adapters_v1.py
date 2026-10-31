"""Freeze preceding canonical codecs and add exact validated default migration."""
from pathlib import Path
import sys,json,hashlib
ROOT=Path(__file__).resolve().parents[4];project=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v4/project'
def main():
 folder=project/'scripts/persistence/pre_rival_career';folder.mkdir(exist_ok=False)
 schema=(ROOT/'patch-notes/scripts/persistence/checkpoint_schema.gd').read_text(encoding='utf-8');schema=schema.replace('class_name CheckpointSchema','',1);(folder/'schema.gd').write_bytes(schema.encode())
 studio=(ROOT/'patch-notes/scripts/persistence/studio_checkpoint.gd').read_text(encoding='utf-8');studio=studio.replace('class_name StudioCheckpoint','',1).replace('CheckpointSchema','PreviousSchema');studio=studio.replace('extends RefCounted','extends RefCounted\nconst PreviousSchema := preload("res://scripts/persistence/pre_rival_career/schema.gd")',1);(folder/'studio.gd').write_bytes(studio.encode())
 world=(ROOT/'patch-notes/scripts/market/rival_world_checkpoint.gd').read_text(encoding='utf-8').replace('CheckpointSchema','PreviousSchema').replace('StudioCheckpoint','PreviousStudio');world=world.replace('extends RefCounted','extends RefCounted\nconst PreviousSchema := preload("res://scripts/persistence/pre_rival_career/schema.gd")\nconst PreviousStudio := preload("res://scripts/persistence/pre_rival_career/studio.gd")',1);(folder/'world.gd').write_bytes(world.encode())
 f=project/'scripts/persistence/studio_checkpoint.gd';s=f.read_text(encoding='utf-8');s=s.replace('var error := ""','const CareerPrevious := preload("res://scripts/persistence/pre_rival_career/studio.gd")\nvar error := ""',1)
 methods='''
func _pre_calendar(payload: Dictionary) -> bool:
	return payload.get("run") is Dictionary and not payload.run.has("calendar_start_year")

func upgrade_pre_calendar(payload: Dictionary,active_rival: bool=false) -> Dictionary:
	var previous := CareerPrevious.new()
	var reason: String=previous.validate_active_rival(payload) if active_rival else previous.validate(payload)
	if not reason.is_empty():error=reason;return {}
	var run: RunState=previous.hydrate(payload,active_rival)
	if run==null:error=previous.error;return {}
	# All original values came through the preceding validated codec. Only new
	# defaults are supplied by RunState; never rebuild ownership or active work.
	return capture(run,StringName(payload.get("active_project_id","")))
'''
 s+=methods
 for marker in ['func _validate(payload: Dictionary, active_rival: bool) -> String:','func hydrate(payload: Dictionary, active_rival: bool = false) -> RunState:']:
  assert marker in s
  call='_validate(upgraded,active_rival)' if '_validate(' in marker else 'hydrate(upgraded,active_rival)'
  bad='error' if '_validate(' in marker else 'null'
  s=s.replace(marker,marker+'\n\tif _pre_calendar(payload):\n\t\tvar upgraded:=upgrade_pre_calendar(payload,active_rival)\n\t\treturn '+bad+' if upgraded.is_empty() else '+call,1)
 marker='func _decode_payload(payload: Dictionary, active_rival: bool = false) -> Dictionary:'
 assert marker in s
 s=s.replace(marker,marker+'\n\tif _pre_calendar(payload):\n\t\tvar upgraded:=upgrade_pre_calendar(payload,active_rival)\n\t\treturn {} if upgraded.is_empty() else _decode_payload(upgraded,active_rival)',1)
 f.write_bytes(s.encode())
 f=project/'scripts/market/rival_world_checkpoint.gd';s=f.read_text(encoding='utf-8');s=s.replace('var error := ""','const CareerPreviousWorld := preload("res://scripts/persistence/pre_rival_career/world.gd")\nvar error := ""',1)
 marker='func _read(payload: Dictionary, player_payload: Dictionary, captured_source_identity: String = "") -> Dictionary:';assert marker in s
 addition='''
	if player_payload.get("run") is Dictionary and not player_payload.run.has("calendar_start_year"):
		var previous:=CareerPreviousWorld.new()
		# Code-owned exact prior runtime; never accept a source supplied by data.
		var native: Dictionary=previous._read(payload,player_payload,"673d2891707ec1092aff6d929a92c96ff38f3f8a620754f5de3d0d3ffc9325d1")
		if native.is_empty():error=previous.error;return {}
		for row: Dictionary in native.rows:row.offset=0
		return native
'''
 s=s.replace(marker,marker+addition,1);f.write_bytes(s.encode())
 print('Added exact preceding codec/schema/world adapters, with epoch1980 defaults and no new-cohort route.')
if __name__=='__main__':main()
