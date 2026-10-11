extends "res://../docs/codex/findings/education-e4-compatibility-v1/probe.gd"

func verify_run(run: RunState, original: Dictionary) -> Dictionary:
	var payload := StudioCheckpoint.new().capture(run)
	check(not payload.is_empty(),"new rich schema capture valid")
	if payload.is_empty(): return {}
	check(legacy_projection(payload,original)==normalized(original),"every prior rich field preserved exactly")
	check(payload.run.studio_traits==original.run.studio_traits,"historical traits identical")
	check(payload.run.studio_finance.schema_version=="6" and payload.content_revision!=original.content_revision,"new finance/content version")
	check(payload.run.cash_cents=="1684767" and payload.run.completed_run_cycles=="54","original rich cash and cycle")
	check(finance_inactive(run.get_studio_finance_snapshot()),"no education activation")
	check(payload.run.studio_finance.actions.size()==59 and payload.run.studio_finance.transactions.size()==198 and payload.run.studio_finance.obligations.size()==38,"rich journal lengths unchanged")
	check(payload.run.fanbase.fans=="240" and payload.run.released_games.size()==3,"Fan/release baseline intact")
	return payload

func verify(path: String, fixture: String) -> void:
	var original := read_payload(fixture)
	var c := coordinator(path)
	if c==null: return
	var before := hashes(path)
	var inspected := c.store.inspect()
	var run := c.load_current()
	if not check(run!=null,"rich cold current-schema Continue"): c.free(); return
	c.entered_studio(true)
	var payload := verify_run(run,original)
	check(normalized(inspected.payload)==payload,"rich cold payload exact")
	check(hashes(path)==before,"rich cold Continue writes no files")
	report.merge({"capture":payload,"stored":inspected.payload,"files_before":before,"files_after":hashes(path)})
	c.free()
