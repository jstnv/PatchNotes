from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v20/project'
f=P/'scripts/market/rival_career_policy.gd';s=f.read_text();s=s.replace('if affordability[0]:all_affordable=run.can_complete_productive_cycle(-fee_ceiling)','if affordability[0]:all_affordable=fee_ceiling==0 or run.can_complete_productive_cycle(-fee_ceiling)',1);s=s.replace('if provider!=null and provider.get_script().resource_path','if provider!=null and provider.get_script()!=null and provider.get_script().resource_path',1);f.write_bytes(s.encode())
f=P/'scripts/market/rival_world.gd';s=f.read_text();s=s.replace('var report: Dictionary=joined[id]\n\t\t\tif not report.get', '''if not joined.get(id) is Dictionary:
				_busy=false;_scheduler_failed=true
				return {"ok":false,"reason":"Independent owner returned no result","completed_studios":joined,"cycle":cycle,"requires_checkpoint_recovery":true}
			var report: Dictionary=joined[id]
			if not report.get''',1);s=s.replace('or decision.policy.get_script()!=','or decision.policy==null or decision.policy.get_script()!=',1);f.write_bytes(s.encode())
f=P/'scripts/market/rival_world_checkpoint.gd';s=f.read_text();s=s.replace('func _capture_development(session: RefCounted) -> Variant:','func _snapshot_development(session: RefCounted) -> Variant:',1);s=s.replace('\treturn _encode(state,_development_schema(dev.phase_index))','''	# Only plain detached values cross to the writer; no Project/Hand/Card objects.
	return state.duplicate(true)

func _capture_development(session: RefCounted) -> Variant:
	var state: Variant=_snapshot_development(session)
	return null if state==null else _encode(state,_development_schema(state.phase_index))''',1);s=s.replace('var development: Variant = _capture_development(session)','var development: Variant = _snapshot_development(session)',1);needle='\tfor row: Dictionary in payload.studios:\n\t\tif payload.schema_version=="3":';assert needle in s;s=s.replace(needle,'''\tfor row: Dictionary in payload.studios:
		if row.development!=null:
			row.development=_encode(row.development,_development_schema(int(row.development.phase_index)))
			if not error.is_empty():return {}
		if payload.schema_version=="3":''',1);f.write_bytes(s.encode())
f=P/'scripts/persistence/checkpoint_write_validator.gd';s=f.read_text();needle='\tvar catalog_identity:=_catalog_content()';assert needle in s;s=s.replace(needle,'''\tvar generation:=CheckpointCodec.new()
	var sequence: Variant=generation.integer(payload.get("sequence"))
	if not generation.error.is_empty() or sequence<1 or sequence>RunState.MAX_SIGNED_INT:return _validate_uncached(payload)
	var identity: Dictionary=payload.duplicate();identity.sequence="1"
	var catalog_identity:=_catalog_content()''',1);s=s.replace('catalog_identity,payload])','catalog_identity,identity])',1);f.write_bytes(s.encode())
(P/'export_presets.cfg').write_bytes((P.parents[1]/'rival-quality-1977-20261030-v19/project/export_presets.cfg').read_bytes())
print('Detached native phase snapshots, same wire schema; strict generation proof normalization.')
