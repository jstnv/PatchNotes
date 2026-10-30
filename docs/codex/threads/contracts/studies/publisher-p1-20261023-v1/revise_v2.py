from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[6];HERE=Path(__file__).resolve().parent
P=ROOT/'docs/codex/threads/contracts/simulators/publisher-relationships-foundation-v2/project'
def edit(name,old,new):
    p=P/name;s=p.read_text(encoding='utf-8');assert s.count(old)==1,(name,s.count(old));p.write_text(s.replace(old,new),encoding='utf-8')
edit('scripts/persistence/studio_checkpoint.gd','func _decode_payload(payload: Dictionary, active_rival: bool = false) -> Dictionary:\n','''func _decode_payload(payload: Dictionary, active_rival: bool = false) -> Dictionary:
	if payload.get("content_revision", "") == RelationshipPrevious.new().revision():
		var upgraded := upgrade_relationship_predecessor(payload,active_rival)
		return {} if upgraded.is_empty() else _decode_payload(upgraded,active_rival)
''')
source=json.loads((HERE/'world-baseline.json').read_text(encoding='utf-8'))['world']['source_identity']
edit('scripts/market/rival_world_checkpoint.gd','const MAX_RIVALS := 8',f'''# Exact P1 preceding canonical source, tested with an unmodified whole-world
# payload. Paired content revisions are checked before ordinary validation.
const RELATIONSHIP_PREDECESSOR_SOURCE := "{source}"
const MAX_RIVALS := 8''')
edit('scripts/market/rival_world_checkpoint.gd','\tvar source_ok: bool = payload.get("source_identity")==Replay.source_identity() or payload.get("source_identity") in COMPATIBLE_MARKET_PRESENTATION_SOURCES','''	var relationship_predecessor: bool = payload.get("source_identity") == RELATIONSHIP_PREDECESSOR_SOURCE
	if relationship_predecessor:
		var old_revision: String = StudioCheckpoint.RelationshipPrevious.new().revision()
		if player_payload.get("content_revision") != old_revision or not payload.get("studios") is Array:
			error = "Mismatched relationship predecessor pair"; return {}
		for row: Variant in payload.studios:
			if not row is Dictionary or not row.get("run") is Dictionary or row.run.get("content_revision") != old_revision:
				error = "Mismatched relationship predecessor Studio"; return {}
	var source_ok: bool = payload.get("source_identity")==Replay.source_identity() or payload.get("source_identity") in COMPATIBLE_MARKET_PRESENTATION_SOURCES or relationship_predecessor''')
edit('scripts/debug/verify_contract_challenge_publishers.gd','\t\t\told_record.run.erase("founding_roster_version")','\t\t\told_record.run.erase("publisher_relationships") # Constructed old shape predates P1.\n\t\t\told_record.run.erase("founding_roster_version")')
print('V2 source fence:',source)
