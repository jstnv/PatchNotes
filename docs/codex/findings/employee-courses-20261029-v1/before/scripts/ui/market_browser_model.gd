## Presentation-only projection of the authoritative actual-release query.
extends RefCounted

const Index := preload("res://queries/market_release_index.gd")

static func query(run: RunState, world: RivalWorld = null) -> Dictionary:
	if run == null: return {"ok":false,"reason":"No Studio is available."}
	if world != null and world.player != run:
		return {"ok":false,"reason":"Market and current Studio do not match."}
	var source := world
	if source == null:
		source = RivalWorld.new()
		source.player = run
	var result := Index.query(source)
	if not result.ok: return {"ok":false,"reason":"Market records are unavailable for this Studio.","reason_code":str(result.reason)}
	var rows: Array = result.rows
	for row: Dictionary in rows:
		row["player_owned"] = row.studio_id == str(run._bank_run_id)
		var producer: RunState = run
		if world != null and not row.player_owned: producer = world.studios[StringName(row.studio_id)].run
		row["publisher_owned"] = producer.get_release_metadata(StringName(row.release_id)).get("owner",&"studio") == &"publisher"
		var support := producer.get_support_history()
		if support.deals.has(StringName(row.release_id)):
			row.support = {"terms":support.deals[StringName(row.release_id)],"rights":support.rights[StringName(row.release_id)]}
	rows.reverse() # Index supplies stable release-cycle/owner/ID ordering.
	return {"ok":true,"rows":rows}
