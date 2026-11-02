## Detached component-validation fixtures; not claimed legal license/support careers.
## Actual career's whole typed Studio save and cold restore are checked separately.
extends RefCounted
const Royalty=preload("res://scripts/engines/engine_royalty.gd")
const Commission=preload("res://scripts/contracts/publisher_commission_trial.gd")
const Support=preload("res://scripts/contracts/publisher_support.gd")
const Market=preload("res://scripts/engines/engine_marketplace.gd")
var checks:=0
var failures:=0
var cases: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ","ROYALTY_REGRESSION ",label)
	if not ok:failures+=1
	cases.append({"label":label,"ok":ok})
func add(series: Dictionary,cycle: int,value: int) -> void:series[cycle]=int(series.get(cycle,0))+value
func expected_after_cut(series: Dictionary,rate: int) -> Dictionary:
	# Independent bounded integer oracle; test title totals are below200000 cents.
	var result: Dictionary={};var cumulative:=0
	var cycles: Array=series.keys();cycles.sort()
	for cycle: int in cycles:
		var amount: int=series[cycle]
		var cut: int=((cumulative+amount)*rate)/10000-(cumulative*rate)/10000
		result[cycle]=amount-cut;cumulative+=amount
	return result
func replace_public_binding(d: Dictionary,id: StringName,kind: StringName,origin: String) -> void:
	var row: Dictionary=d.engine_features.engines[&"public_action"].duplicate(true)
	row.kind=kind;row.origin=origin
	if id!=&"public_action" and not (kind==&"proprietary" and d.engine_features.engines.has(id)):d.engine_features.engines[id]=row
	for release: StringName in d.release_engine_ids:
		if d.release_engine_ids[release]==&"public_action":d.release_engine_ids[release]=id
	if kind==&"rival_licensed":d.engine_entitlements.licensed_ids.assign([id])
	if id==&"legacy_engine":
		d.engine_entitlements.version=1;d.engine_entitlements.erase("public_ids")
		d.engine_entitlements.owned_ids.push_front(&"legacy_engine");d.engine_entitlements.selected_engine_id=&"legacy_engine"
func rewrite_expected_finance(d: Dictionary,target: StringName,rate: int) -> void:
	var earned: Dictionary={};var settled: Dictionary={}
	for id: StringName in d.released_games:
		if d.commission_deals.has(id):continue
		var history: Dictionary={"earned":{},"settled":{}}
		if d.support_deals.has(id):history=Support.title_history(d.support_deals[id],d.released_games[id],d.release_metadata[id].release_cycle)
		else:
			var report: Dictionary=ReleasedGameMonthlyReport.build(d.released_games[id],d.release_metadata[id].release_cycle)
			for row: Dictionary in report.rows:
				for slice: Dictionary in row.slices:add(history.earned,slice.run_cycle,slice.net_cents)
				for payment: Dictionary in row.payments:add(history.settled,payment.run_cycle,payment.cents)
		var title_rate: int=rate if d.release_engine_ids.get(id,&"legacy_engine")==target else 0
		var e:=expected_after_cut(history.earned,title_rate);var paid:=expected_after_cut(history.settled,title_rate)
		for cycle: int in e:add(earned,cycle,e[cycle])
		for cycle: int in paid:add(settled,cycle,paid[cycle])
	for action: Dictionary in d.studio_finance.actions:
		if action.productive:action.sales_earned=earned.get(action.cycle,0);action.settled=settled.get(action.cycle,0)
func changed_income(d: Dictionary,typed: bool=false) -> Dictionary:
	var result:=d.duplicate(true)
	for action: Dictionary in result.studio_finance.actions:
		if action.productive and action.sales_earned>0:
			action.sales_earned=float(action.sales_earned) if typed else int(action.sales_earned)+1;break
	return result
func changed_settlement(d: Dictionary,typed: bool=false) -> Dictionary:
	var result:=d.duplicate(true)
	for action: Dictionary in result.studio_finance.actions:
		if action.productive and action.settled>0:
			action.settled=float(action.settled) if typed else int(action.settled)+1;break
	return result
func run_for(run: RunState) -> Dictionary:
	var base: Dictionary=StudioCheckpoint.new().snapshot(run).run
	check(Commission.valid_save(base),"Actual full Public-funded commission validates")
	var public_title: StringName=&""
	for id: StringName in base.release_engine_ids:
		if base.release_engine_ids[id]==&"public_action":public_title=id;break
	var owned: StringName=run.get_selected_engine_id()
	for spec in [[&"public_action",&"public",preload("res://scripts/engines/public_action_engine.gd").ORIGIN,3000],[&"puzzle_engine",&"rival_licensed","legacy-access-v1",2000],[&"puzzle_engine",&"rival_licensed",Market.RIVAL_ORIGIN,1500],[owned,&"proprietary",preload("res://scripts/engines/proprietary_engine_state.gd").ORIGIN,0],[&"legacy_engine",&"proprietary","legacy-access-v1",0]]:
		var fixture: Dictionary=base.duplicate(true)
		replace_public_binding(fixture,spec[0],spec[1],spec[2]);rewrite_expected_finance(fixture,spec[0],spec[3])
		check(Commission.valid_save(fixture),"Detached correct frozen rate accepted "+str(spec[0])+"/"+str(spec[3]))
		check(not Commission.valid_save(changed_income(fixture)),"One-cent earned mutation rejected "+str(spec[3]))
		check(not Commission.valid_save(changed_income(fixture,true)),"Float finance amount rejected "+str(spec[3]))
		check(not Commission.valid_save(changed_settlement(fixture)),"One-cent settlement mutation rejected "+str(spec[3]))
		check(not Commission.valid_save(changed_settlement(fixture,true)),"Float settlement amount rejected "+str(spec[3]))
		var duplicate:=fixture.duplicate(true);duplicate.studio_finance.actions.append(duplicate.studio_finance.actions.filter(func(a):return a.productive)[0].duplicate(true))
		check(not Commission.valid_save(duplicate),"Duplicate productive source rejected "+str(spec[3]))
		var wrong:=fixture.duplicate(true);rewrite_expected_finance(wrong,spec[0],1000 if int(spec[3])!=1000 else 0)
		check(not Commission.valid_save(wrong),"Wrong retained ratio rejected "+str(spec[3]))
	for spec in [[&"public_action",preload("res://scripts/engines/public_action_engine.gd").ORIGIN,3000],[&"puzzle_engine","legacy-access-v1",2000],[&"puzzle_engine",Market.RIVAL_ORIGIN,1500]]:
		var fixture: Dictionary=base.duplicate(true)
		replace_public_binding(fixture,spec[0],&"public" if spec[0]==&"public_action" else &"rival_licensed",spec[1])
		fixture.support_deals[public_title]={"budget_cents":87500}
		rewrite_expected_finance(fixture,spec[0],spec[2])
		check(Commission.valid_save(fixture),"Support recoup precedes engine cut "+str(spec[2]))
		check(not Commission.valid_save(changed_income(fixture)),"Supported one-cent mutation rejected "+str(spec[2]))
	var historical:=base.duplicate(true)
	replace_public_binding(historical,&"legacy_engine",&"proprietary","legacy-access-v1")
	for id: StringName in historical.release_engine_ids.keys():
		if historical.release_engine_ids[id]==&"legacy_engine":historical.release_engine_ids.erase(id)
	rewrite_expected_finance(historical,&"legacy_engine",0)
	check(Commission.valid_save(historical),"Existing v1 unbound historical Legacy zero-cut rule retained")
	var missing:=base.duplicate(true);missing.release_engine_ids.erase(public_title)
	check(not Commission.valid_save(missing),"Current Public release missing binding rejected")
	var wrong_type:=base.duplicate(true);wrong_type.release_engine_ids[public_title]="public_action"
	check(not Commission.valid_save(wrong_type),"String instead of typed engine ID rejected")
	var unknown:=base.duplicate(true);unknown.release_engine_ids[public_title]=&"unbound_engine"
	check(not Commission.valid_save(unknown),"Unknown source engine rejected")
	var invalid:=base.duplicate(true);invalid.engine_features.engines[&"public_action"].origin="forged"
	check(not Commission.valid_save(invalid),"Invalid engine terms origin rejected")
	var forged:=base.duplicate(true);forged.released_games[public_title].release_id=&"forged_title"
	check(not Commission.valid_save(forged),"Release record source identity mutation rejected")
	check(Royalty.retained_series({1:3,2:4},{2:7},3000)=={"earned":{1:3,2:2},"settled":{1:0,2:5}},"Independent cumulative earned/settled rounding")
	for args in [[{1:1.0},{},3000],[{1:1},{1:1.0},3000],[{"1":1},{},3000],[{1:-1},{},3000],[{1:1},{1:2},3000],[{1:9223372036854775807,2:1},{},3000],[{1:1},{},3000.0],[{1:1},{},-1],[{1:1},{},10001]]:
		check(Royalty.retained_series(args[0],args[1],args[2]).is_empty(),"Malformed/overflow series rejected "+str(args))
	return {"checks":checks,"failures":failures,"cases":cases,"scope":"Detached per-title validator fixtures; actual career cold/save/replay checked separately"}
