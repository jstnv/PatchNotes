extends SceneTree

const Before := preload("res://scripts/debug/fixtures/finance_before_campaign_latency.gd")
var checks := 0
var failures := 0
var measurements: Dictionary = {}
var disk_validations := 0

class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer!=null: return true
		var server:=TCPServer.new()
		if server.listen(47921,"127.0.0.1")!=OK: return false
		_writer=server
		return true

class ChangedReadback extends PrivateStore:
	var change := false
	func _read_path(path: String, sequence: int, validation_scope: Variant = null) -> Dictionary:
		if change and path.ends_with(".tmp"):
			var codec:=CheckpointCodec.new()
			var value:=codec.open_envelope(FileAccess.get_file_as_string(path))
			value.marker="no"
			var file:=FileAccess.open(path,FileAccess.WRITE)
			file.store_string(codec.envelope(value))
			file.close()
		return super._read_path(path,sequence,validation_scope)

func validate_marker(payload: Dictionary) -> String:
	disk_validations+=1
	return "" if payload.get("marker")=="ok" else "Invalid marker"

class CountingStore extends FeatureStore:
	var refreshes := 0
	func _refresh() -> void:
		refreshes += 1
		super._refresh()

class CurrentCheckpoint extends StudioCheckpoint:
	var historical_hashes := 0
	var decodes := 0
	func _decode_payload(payload: Dictionary, active_rival: bool = false) -> Dictionary:
		decodes+=1
		return super._decode_payload(payload,active_rival)
	func _rules_revision(rules: String, legacy_audio_hash: String = "", prior_catalog_hash: String = "") -> String:
		if rules!=RULES: historical_hashes+=1
		return super._rules_revision(rules,legacy_audio_hash,prior_catalog_hash)

class RejectedCheckpoint extends StudioCheckpoint:
	func _decode_payload(_payload: Dictionary, _active_rival: bool = false) -> Dictionary:
		error="Isolated alternate validator rejects"
		return {}

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func elapsed(operation: Callable) -> int:
	var samples: Array[int] = []
	for _sample in 5:
		var start := Time.get_ticks_usec()
		operation.call()
		samples.append(Time.get_ticks_usec()-start)
	samples.sort()
	return samples[2]

func _initialize() -> void:
	await process_frame
	# Constructed solvent CPU fixture, not a playable economy/balance claim.
	var ledger := Before.create(100000000)
	for cycle in range(1,97):
		var next := Before.plan(ledger,cycle,ledger.cash_cents,0,&"calendar",0,0,true)
		expect(not next.is_empty(),"Original finance accepts diagnostic cycle " + str(cycle))
		ledger = next.ledger
	expect(StudioFinanceLedger._is_valid(ledger),"Current finance accepts independently built long history")
	var uncached := elapsed(func(): return Before._is_valid(ledger))
	var repeated := elapsed(func(): return StudioFinanceLedger._is_valid(ledger))
	measurements = {"cycle":96,"original_validation_us":uncached,"repeated_validation_us":repeated}
	expect(repeated*5 < uncached,"Repeated unchanged-history reads avoid the growing replay cost")
	var original := ledger.duplicate(true)
	for field: String in ["cash_before","direct_delta","settled"]:
		ledger.actions[3][field] += 1
		expect(not StudioFinanceLedger._is_valid(ledger),"Same-length nested journal corruption rejects: " + field)
		expect(not StudioFinanceLedger.report(ledger,96,ledger.cash_cents).available,"Corrupt history never supplies a report")
		ledger = original.duplicate(true)
		expect(StudioFinanceLedger._is_valid(ledger),"Restored deep snapshot validates")
	ledger.monthly_rows[0].closing_cash_cents += 1
	expect(not StudioFinanceLedger._is_valid(ledger),"Derived monthly corruption rejects after a previous valid read")
	ledger = original.duplicate(true)
	ledger.credit.score += 1
	expect(not StudioFinanceLedger._is_valid(ledger),"Nested credit corruption rejects")
	ledger = original.duplicate(true)
	ledger.actions[3].cycle = float(ledger.actions[3].cycle)
	expect(not StudioFinanceLedger._is_valid(ledger),"Numerically equal float cannot replace a journal integer")
	ledger = original.duplicate(true)
	ledger.actions[3].kind = String(ledger.actions[3].kind)
	expect(not StudioFinanceLedger._is_valid(ledger),"Equal String cannot replace a journal StringName")
	ledger = original.duplicate(true)
	expect(StudioFinanceLedger.report(ledger,96,ledger.cash_cents)==Before.report(ledger,96,ledger.cash_cents),"Every finance report field equals the independent original")
	expect(StudioFinanceLedger.plan(ledger,97,ledger.cash_cents,-1,&"store",0,0,true,&"fixture")==Before.plan(ledger,97,ledger.cash_cents,-1,&"store",0,0,true,&"fixture"),"Next exact transaction is unchanged")
	for initial in range(1000000,1000012):
		var other := Before.create(initial)
		expect(StudioFinanceLedger._is_valid(other),"Independent Studios do not reuse the wrong validation")
	expect(StudioFinanceLedger._is_valid(original),"Eviction never affects correctness")
	var run := RunState.new()
	run.initialize_cash(0)
	expect(run.create_studio_with_traits("Refresh regression",&"action",[]),"Private Store fixture initializes")
	run.finalize_starter_selection()
	var payload := StudioCheckpoint.new().capture(run)
	var current := CurrentCheckpoint.new()
	expect(current.validate(payload).is_empty(),"Current checkpoint still validates completely")
	expect(current.historical_hashes==0,"Current validation does not hash historical rule sets")
	current.decodes=0
	var next_generation:=payload.duplicate(true)
	next_generation.sequence="7"
	expect(current.validate(next_generation).is_empty() and current.decodes==0,"Identical proven state in a new valid generation does not reconstruct its entire history")
	for bad_sequence: Variant in ["0","01","-1",7.0]:
		var bad:=payload.duplicate(true)
		bad.sequence=bad_sequence
		expect(not current.validate(bad).is_empty(),"Generation normalization still rejects invalid sequence "+str(bad_sequence))
	var tampered:=payload.duplicate(true)
	tampered.run.studio_finance.cash_cents="999999"
	expect(not current.validate(tampered).is_empty(),"Successful whole-state proof does not accept nested finance changes")
	expect(not current.validate_active_rival(payload).is_empty(),"Studio proof cannot authorize an active-rival boundary")
	expect(not RejectedCheckpoint.new().validate(payload).is_empty(),"A different validator script cannot inherit another script's proof")
	for index in 32:
		var alternate:=payload.duplicate(true)
		alternate.run.seen_tutorial_topics.append({"key":"latency-fixture-"+str(index),"value":true})
		expect(current.validate(alternate).is_empty(),"Independent small guidance state validates "+str(index))
	current.decodes=0
	expect(current.validate(payload).is_empty() and current.decodes>0,"Bounded proof eviction falls back to complete validation")
	current.historical_hashes=0
	expect(current.hydrate(payload)!=null,"Current checkpoint hydrates normally")
	expect(current.historical_hashes==0,"Current hydration does not hash historical rule sets")
	current.historical_hashes=0
	expect(not current._decode_payload(payload).is_empty() and current.historical_hashes==0,"Current decoding directly uses the current strict schema")
	var store := CountingStore.new()
	root.add_child(store)
	store.setup(run)
	await process_frame
	await process_frame
	store.refreshes = 0
	run.cash_changed.emit()
	run.features_changed.emit()
	run.sales_changed.emit()
	run.calendar_changed.emit()
	expect(store.refreshes==0,"One transaction's signals do not each rebuild the map synchronously")
	await process_frame
	await process_frame
	expect(store.refreshes==1,"One signal burst produces exactly one current Store refresh")
	store.hide()
	store.refreshes = 0
	run.cash_changed.emit()
	run.features_changed.emit()
	await process_frame
	await process_frame
	expect(store.refreshes==0,"Hidden Store does not rebuild during development")
	store.open_store()
	expect(store.refreshes==1,"Reopening refreshes immediately from authoritative state")
	store.free()
	var disk:=PrivateStore.new("user://latency-scope",validate_marker)
	expect(disk.save({"marker":"ok"}).status==&"saved","Real atomic generation publishes")
	expect(disk_validations==1,"An atomic write validates its identical DTO once, including readback and cleanup")
	var before_reads:=disk_validations
	expect(disk.inspect().status==&"valid" and disk_validations>before_reads,"A separate disk inspection always validates afresh")
	before_reads=disk_validations
	expect(disk.save({"marker":"ok"}).status==&"saved","Second generation publishes")
	expect(disk_validations-before_reads==2,"A subsequent publication validates its old and new DTO once each")
	disk.validator=func(_payload: Dictionary)->String: return "Validator changed"
	expect(disk.inspect().status==&"invalid","Validation proof cannot survive outside its publication scope")
	disk.release_writer()
	var changed:=ChangedReadback.new("user://changed-readback",validate_marker)
	expect(changed.save({"marker":"ok"}).status==&"saved","Readback mutation fixture publishes initial state")
	changed.change=true
	expect(changed.save({"marker":"ok"}).status==&"invalid","Changed readback with a new valid checksum is validated and rejected")
	expect(changed.inspect().sequence==1,"Rejected changed bytes preserve the previous generation")
	changed.change=false
	expect(changed.save({"marker":"ok","number":1}).status==&"invalid","Strict disk parser still rejects numeric JSON in a proven candidate")
	changed.validator=func(value: Dictionary)->String: return "" if typeof(value.get("marker"))==TYPE_STRING_NAME else "ID type changed"
	expect(changed.save({"marker":&"ok"}).status==&"invalid","JSON type erasure cannot reuse a typed candidate's validation")
	changed.release_writer()
	var bounded:=PrivateStore.new("user://bounded-parser",validate_marker)
	var deep: Variant=null
	for _level in 98: deep=[deep]
	expect(bounded.save({"marker":"ok","deep":deep}).status==&"invalid","Trusted serializer cannot bypass strict parser depth budget")
	var huge: Array=[]
	huge.resize(500001)
	expect(bounded.save({"marker":"ok","huge":huge}).status==&"invalid","Trusted serializer cannot bypass strict parser node budget")
	bounded.release_writer()
	var detached:=PrivateStore.new("user://detached-parser",validate_marker)
	var unicode_payload: Dictionary={"marker":"ok","nested":{"é📝":["quote\" slash\\ newline\n","music 🎵"]}}
	expect(detached.save(unicode_payload).status==&"saved","Unicode and escaped values publish on the trusted serializer path")
	var first:=detached.inspect()
	expect(first.payload.nested==unicode_payload.nested,"Cached parser reproduces exact Unicode and escaped values")
	first.payload.nested["é📝"][0]="changed"
	expect(detached.inspect().payload.nested==unicode_payload.nested,"Inspected payload cannot mutate the cached parser proof")
	var published: String=detached._path(1)
	var altered: Dictionary=CheckpointCodec.new().open_envelope(FileAccess.get_file_as_string(published))
	altered.marker="no"
	var replacement:=CheckpointCodec.new().envelope(altered)
	expect(replacement.to_utf8_buffer().size()==FileAccess.get_file_as_bytes(published).size(),"External mutation fixture keeps file size unchanged")
	var external:=FileAccess.open(published,FileAccess.WRITE)
	external.store_string(replacement)
	external.close()
	expect(detached.inspect().status==&"invalid","Same-size external replacement with a valid checksum does not inherit a warm parse or semantic proof")
	expect(detached._parsed_bytes<=StudioCheckpointStore.PARSED_CACHE_BYTES and detached._parsed_envelopes.size()<=StudioCheckpointStore.PARSED_CACHE_LIMIT,"Parser cache retains its byte and entry bounds")
	expect(StudioFinanceLedger._validated_journal_bytes<=StudioFinanceLedger.VALIDATED_JOURNAL_BYTES and StudioFinanceLedger._validated_journals.size()<=StudioFinanceLedger.VALIDATED_JOURNAL_LIMIT,"Finance cache retains its byte and entry bounds")
	detached.release_writer()
	var path := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	var report := {"ok":failures==0,"checks":checks,"failures":failures,"measurements":measurements}
	if not path.is_empty(): FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(failures)
