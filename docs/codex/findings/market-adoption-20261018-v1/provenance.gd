## Negative corruption regressions against an actual legal current-world save.
## --input=<acceptance .checkpoint.json> --output=<new result.json>
## Every mutation owns a deep copy. The input and player saves are never written.
extends SceneTree

const Market := preload("res://scripts/market/market_transaction_trial.gd")
const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Migration := preload("res://scripts/market/market_save_migration_trial.gd")
var checks := 0
var failures := 0
var cases: Array = []
var original: Dictionary = {}

func _arg(prefix: String) -> String:
	for item in OS.get_cmdline_user_args():
		if item.begins_with(prefix): return item.substr(prefix.length())
	return ""

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MARKET_PROVENANCE " + label)
	cases.append({"label":label,"pass":ok})

func _pair() -> Dictionary:
	return {"player":original.player.duplicate(true),"world":original.world.duplicate(true)}

func _reject(pair: Dictionary, label: String) -> void:
	var codec := Codec.new()
	var before := Replay.digest(pair)
	var reason: String=codec.validate(pair.world,pair.player)
	expect(not reason.is_empty(),label)
	cases[-1].reason=reason
	expect(Replay.digest(pair)==before,label+" validation has no mutation")

func _factor(pair: Dictionary, rival: bool = false, capped: bool = false) -> Dictionary:
	var runs: Array=[pair.player]
	if rival:
		runs=[]
		for row: Dictionary in pair.world.studios: runs.append(row.run)
	for run: Dictionary in runs:
		for entry: Dictionary in run.run.released_games:
			for factor: Dictionary in entry.value.market_factors:
				if not factor.value.historical and (not capped or factor.value.factor_bp=="7000"):
					return factor.value
	return {}

func _review(pair: Dictionary, baseline: bool = false) -> Dictionary:
	for entry: Dictionary in pair.player.run.release_metadata:
		var value: Dictionary=entry.value.review
		if value.has("market") and not value.market.historical and ((int(value.market.recent_count)==0) == baseline):
			return {"review":value,"genre":StringName(entry.value.genre)}
	return {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var input := _arg("--input=")
	var output := _arg("--output=")
	if input.is_empty() or output.is_empty():
		push_error("Explicit --input and --output required")
		quit(2)
		return
	var input_hash := FileAccess.get_sha256(input)
	var loaded: Variant=JSON.parse_string(FileAccess.get_file_as_string(input))
	if not loaded is Dictionary or not loaded.get("player") is Dictionary or not loaded.get("world") is Dictionary:
		push_error("Expected legal acceptance player/world checkpoint")
		quit(2)
		return
	original=loaded
	var codec:=Codec.new()
	expect(original.world.source_identity==Replay.source_identity(),"input is current runtime source")
	expect(codec.validate(original.world,original.player).is_empty(),"unmodified actual legal checkpoint validates: "+codec.error)
	if failures>0:
		_finish(input,output,input_hash)
		return
	var pair:=_pair()
	var factor:=_factor(pair)
	expect(not factor.is_empty(),"actual player has a frozen earning factor")
	if factor.is_empty(): _finish(input,output,input_hash); return
	factor.snapshot_id="unrelated"
	_reject(pair,"arbitrary factor source ID rejected")

	pair=_pair(); factor=_factor(pair)
	factor.snapshot_id="market-v2-%s-%s"%[factor.cycle_start,"0".repeat(64)]
	var native: Variant=CheckpointCodec.new().decode(factor,CheckpointSchema.market_factor())
	expect(Market.valid_factor(native),"forged factor hash has a locally valid shape and arithmetic")
	_reject(pair,"valid-shape forged historical factor hash rejected against actual releases")

	pair=_pair(); factor=_factor(pair)
	var future: int=(int(pair.world.cycle)+100)*2
	factor.cycle_start=str(future)
	factor.snapshot_id="market-v2-%d-%s"%[future,"1".repeat(64)]
	native=CheckpointCodec.new().decode(factor,CheckpointSchema.market_factor())
	expect(Market.valid_factor(native),"future factor has valid isolated shape")
	_reject(pair,"future age-month factor rejected")

	pair=_pair(); factor=_factor(pair,true,true)
	expect(not factor.is_empty(),"actual rival has a capped market factor")
	if not factor.is_empty():
		factor.genre_only=str(int(factor.genre_only)+1)
		native=CheckpointCodec.new().decode(factor,CheckpointSchema.market_factor())
		expect(Market.valid_factor(native),"changed capped bucket leaves factor and all money arithmetic unchanged")
		_reject(pair,"valid-arithmetic false crowding count rejected")

	pair=_pair()
	var review:=_review(pair)
	expect(not review.is_empty(),"actual player completed a pressured project")
	if not review.is_empty():
		var details: Dictionary=review.review.market
		details.recent_count=str(int(details.recent_count)+1)
		details.density_lift=str(mini(4,int(details.recent_count)*2))
		for i in range(4): details.standards[i]=str(int(details.base[i])+maxi(int(details.density_lift),int(details.benchmark_lifts[i])))
		review.review.standards=details.standards.duplicate()
		native=CheckpointCodec.new().decode(details,CheckpointSchema.market_details())
		expect(Market.valid_details(native,review.genre),"forged target remains internally consistent")
		_reject(pair,"consistent false target rejected against original source facts")

	pair=_pair(); factor=_factor(pair)
	factor.historical=true
	_reject(pair,"current snapshot cannot masquerade as historical by flag alone")

	pair=_pair(); factor=_factor(pair)
	factor.snapshot_id="pre-market-neutral:"+Migration.OldSource
	_reject(pair,"current factor cannot use historical source without historical marker")

	# This old-source exemption must be backed by a recorded actual migration,
	# not just a recognizable source ID on a freshly created current campaign.
	pair=_pair(); review=_review(pair,true)
	expect(not review.is_empty(),"current campaign contains its real baseline first project")
	if not review.is_empty():
		review.review.market.historical=true
		review.review.market.snapshot_id="pre-market-neutral:"+Migration.OldSource
		_reject(pair,"current first project cannot acquire invented historical provenance")

	pair=_pair()
	var market: Variant=CheckpointCodec.new().decode(pair.world.market,Codec._market_schema())
	expect(not market.facts.is_empty(),"current snapshot contains actual releases")
	if not market.facts.is_empty():
		market.facts[0].review_tenths=(market.facts[0].review_tenths+1)%101
		market.id=Market.identifier(market.cycle_start,market.facts)
		expect(Market.valid(market),"forged current snapshot has a valid recomputed hash")
		pair.world.market=CheckpointCodec.new().encode(market,Codec._market_schema())
		_reject(pair,"valid-hash current snapshot cannot change owner release facts")
	_finish(input,output,input_hash)

func _finish(input: String, output: String, input_hash: String) -> void:
	expect(FileAccess.get_sha256(input)==input_hash,"original legal checkpoint bytes preserved")
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file==null: push_error("Cannot open result output"); quit(2); return
	file.store_string(JSON.stringify({"source_identity":Replay.source_identity(),"input":input,"input_sha256":input_hash,"checks":checks,"failures":failures,"cases":cases},"\t"))
	file.close()
	print("MARKET_PROVENANCE checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
