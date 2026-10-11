extends SceneTree

var checks := 0
var failures: Array[String] = []
var report: Dictionary = {}
var output := ""

func _initialize() -> void: call_deferred("_run")

func check(value: bool, label: String) -> bool:
	checks += 1
	if not value: failures.append(label); printerr("E4_ASSERT: ",label)
	return value

func coordinator(path: String) -> CheckpointCoordinator:
	var c := CheckpointCoordinator.new()
	c.store = StudioCheckpointStore.new(path,c.adapter.validate)
	c.store._writer = TCPServer.new()
	if not check(c.store._writer.listen(48971,"127.0.0.1")==OK,"isolated48971 lease"):
		c.free(); return null
	root.add_child(c)
	return c

func normalized(payload: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	result.sequence = "1"
	return result

func legacy_projection(payload: Dictionary, original: Dictionary) -> Dictionary:
	var projected := normalized(payload)
	projected.content_revision = original.content_revision
	projected.run.studio_finance.erase("education")
	projected.run.studio_finance.schema_version = "5"
	return projected

func read_payload(path: String) -> Dictionary:
	var codec := CheckpointCodec.new()
	var payload := codec.open_envelope(FileAccess.get_file_as_string(path))
	check(codec.error.is_empty(),"strict envelope read "+path)
	return payload

func hashes(path: String) -> Dictionary:
	var result := {}
	for name in DirAccess.get_files_at(path): result[name] = FileAccess.get_sha256(path.path_join(name))
	return result

func finance_inactive(finance: Dictionary) -> bool:
	if not finance.education.is_empty(): return false
	for bill: Dictionary in finance.obligations:
		if bill.expense_type==&"student_loan": return false
	for action: Dictionary in finance.actions:
		if action.get("operation",{}).get("type") in [&"education_open",&"education_payoff"]: return false
	return true

func verify_run(run: RunState, original: Dictionary) -> Dictionary:
	var payload := StudioCheckpoint.new().capture(run)
	check(not payload.is_empty(),"new schema capture valid")
	if payload.is_empty(): return {}
	check(legacy_projection(payload,original)==normalized(original),"all prior fields preserved exactly")
	check(payload.run.studio_traits==original.run.studio_traits,"canonical historical traits identical")
	check(payload.run.studio_finance.schema_version=="6","finance6")
	check(payload.content_revision!=original.content_revision,"new content revision")
	check(payload.run.cash_cents=="570000" and payload.run.completed_run_cycles=="0","original creation cash and time")
	check(finance_inactive(run.get_studio_finance_snapshot()),"no education account or bills")
	return payload

func migrate(path: String, fixture: String) -> void:
	var original := read_payload(fixture)
	var c := coordinator(path)
	if c==null: return
	var before := hashes(path)
	var run := c.load_current()
	if not check(run!=null,"legacy real Continue"): c.free(); return
	c.entered_studio(true)
	check(hashes(path)==before and not c.pending,"restored entry performs no write")
	var payload := verify_run(run,original)
	check(c.retry(),"coordinator publishes new schema")
	var inspected := c.store.inspect()
	check(inspected.status==&"valid" and inspected.sequence==2,"valid generation2")
	check(normalized(inspected.payload)==payload,"published payload exactly captured")
	check(FileAccess.get_sha256(path.path_join("checkpoint.1.json"))==FileAccess.get_sha256(fixture),"original generation1 exact bytes")
	report.merge({"original":original,"capture":payload,"stored":inspected.payload,"files_before":before,"files_after":hashes(path)})
	c.free()

func verify(path: String, fixture: String) -> void:
	var original := read_payload(fixture)
	var c := coordinator(path)
	if c==null: return
	var before := hashes(path)
	var inspected := c.store.inspect()
	var run := c.load_current()
	if not check(run!=null,"cold new schema Continue"): c.free(); return
	c.entered_studio(true)
	var payload := verify_run(run,original)
	check(normalized(inspected.payload)==payload,"cold payload exact")
	check(hashes(path)==before,"cold Continue writes no files")
	var finance := run.get_studio_finance_snapshot()
	var boundaries := {}
	for cycle in range(1,29):
		var income := 50000 if cycle%2==0 else 0
		var result := StudioFinanceLedger.plan(finance,cycle,finance.cash_cents,income,&"other_income",0,0,true,&"e4_component_rent_funding")
		if not check(not result.is_empty(),"detached component productive cycle%d"%cycle): break
		finance = result.ledger
		check(finance_inactive(finance),"detached preview inactive at%d"%cycle)
		check(finance.cash_cents==570000,"detached component rent funding exact at%d"%cycle)
		if cycle in [24,26,28]: boundaries[str(cycle)] = finance.duplicate(true)
	check(StudioFinanceLedger._is_valid(finance),"component journal strict valid")
	check(c.adapter.capture(run)==payload and hashes(path)==before,"component fixture never changes restored run or saves")
	report.merge({"capture":payload,"stored":inspected.payload,"files_before":before,"files_after":hashes(path),"component_boundaries":boundaries,"component_fixture":true,"synthetic_income_per_even_cycle_cents":50000})
	c.free()

func reject(path: String, fixture: String) -> void:
	var original := read_payload(fixture)
	var cases := ["unsupported_revision","checksum","numeric_cash","extra_education","old_version6","cash_discontinuity","retroactive_refund"]
	var records := {}
	for name: String in cases:
		var case_path := path.path_join(name)
		var c := coordinator(case_path)
		if c==null: return
		var before := hashes(case_path)
		var inspected := c.store.inspect()
		var expected: StringName = &"incompatible" if name=="unsupported_revision" else &"invalid"
		check(inspected.status==expected,"negative classification "+name)
		check(c.load_current()==null and c.run==null and c.last_payload.is_empty(),"failed Continue attaches no run "+name)
		check(hashes(case_path)==before,"rejection preserves exact bytes "+name)
		var reason: String = str(inspected.get("reason",""))
		var recovery := c.store.recover_backup()
		var recovery_path := case_path
		if name=="unsupported_revision":
			check(recovery.status==&"invalid" and hashes(case_path)==before,"unsupported backup recovery forbidden, bytes retained")
			c.free()
			recovery_path = path.path_join("unsupported-valid-copy")
			c = coordinator(recovery_path)
			if c==null: return
		else:
			check(recovery.status==&"saved" and recovery.sequence==3,"explicit valid backup recovery "+name)
			check(FileAccess.get_sha256(case_path.path_join("checkpoint.2.json"))==before["checkpoint.2.json"],"damaged bytes retained after recovery "+name)
		var run := c.load_current()
		if check(run!=null,"valid Continue after rejection "+name):
			c.entered_studio(true)
			var payload := verify_run(run,original)
			records[name] = {"classification":expected,"reason":reason,"before":before,"rejected_directory_after":hashes(case_path),"recovery_directory":recovery_path,"recovery_files":hashes(recovery_path),"capture":payload}
		c.free()
	report.records = records

func verify_recovery(path: String, fixture: String) -> void:
	var original := read_payload(fixture)
	var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var records := {}
	for name: String in prior.records:
		var item: Dictionary = prior.records[name]
		var c := coordinator(item.recovery_directory)
		if c==null: return
		var before := hashes(item.recovery_directory)
		check(before==item.recovery_files,"recovery endpoint input exact "+name)
		var run := c.load_current()
		if check(run!=null,"fresh process recovered Continue "+name):
			c.entered_studio(true)
			var payload := verify_run(run,original)
			check(payload==item.capture,"cold recovery exact "+name)
			check(hashes(item.recovery_directory)==before,"cold recovery no write "+name)
			records[name] = {"capture":payload,"files":before}
		c.free()
	report.records = records

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0]
	output = args[3]
	report = {"mode":mode,"fixture":args[2],"path":args[1]}
	match mode:
		"migrate": migrate(args[1],args[2])
		"verify": verify(args[1],args[2])
		"reject": reject(args[1],args[2])
		"verify_recovery": verify_recovery(args[1],args[2])
		_: check(false,"unknown mode")
	report.checks = checks
	report.failures = failures
	report.passed = failures.is_empty()
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report))
	print("E4_COMPATIBILITY ",mode," checks=",checks," assertions_rejected=",failures.size())
	quit(0 if failures.is_empty() else 1)
