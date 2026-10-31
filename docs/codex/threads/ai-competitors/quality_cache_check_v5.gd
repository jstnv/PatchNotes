extends SceneTree
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const Book:=preload("res://scripts/market/rival_standard_book.gd")
const Validator:=preload("res://scripts/persistence/checkpoint_write_validator.gd")
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
var issues: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:issues.append(label);push_error(label)
func arg(prefix: String) -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(prefix):return value.trim_prefix(prefix)
	return ""
func _initialize() -> void:
	await process_frame
	var c: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://certified/rival-opening-5607-v1.json"))
	var adapter:=StudioCheckpoint.new();var p: Dictionary=c.fixture.player;var r:=adapter.hydrate(p)
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var codec:=Codec.new();var world:=codec.restore(c.fixture.world,p,r,catalog,"0d8e6b57ddaa3c2a71c05af7ba92a4a4495cad5da80c7dad38b4b038f991fc99")
	check(world!=null,"Exact trusted private v12 fixture imports")
	if world==null:finish();return
	check(codec._decoded_runs.is_empty() and not codec._decode_scope,"Native decode scope is cleared")
	var body: Dictionary=adapter.capture(r);body.rival_world=codec.capture(world)
	var validator:=Validator.new();validator.rival_catalog=catalog;validator._publishing_source_identity=Replay.source_identity()
	check(validator._validate_payload(body).is_empty(),"First complete generation validates")
	check(validator._validate_payload(body).is_empty(),"Exact warm predicate validates")
	var identity: PackedByteArray=validator._catalog_content();var card: CardData=catalog.cards.values()[0];var old:=card.primary_value;card.primary_value+=1
	check(validator._catalog_content()!=identity,"Catalog Core values fence proof independently of IDs")
	card.primary_value=old;check(validator._catalog_content()==identity,"Restoring catalog restores exact context")
	var generation: Dictionary=body.duplicate(true);generation.sequence="2"
	check(validator._validate_payload(generation).is_empty(),"Separately valid positive generation reuses same predicate")
	generation.sequence="0";check(not validator._validate_payload(generation).is_empty(),"Normalized proof rejects zero generation")
	generation.sequence=1.0;check(not validator._validate_payload(generation).is_empty(),"Normalized proof rejects float generation")
	var original: Dictionary=c.fixture.world.duplicate(true);original.erase("source_identity")
	var captured: Dictionary=body.rival_world.duplicate(true);captured.erase("source_identity")
	FileAccess.open(arg("--output=").get_base_dir()+"/before.json",FileAccess.WRITE).store_string(JSON.stringify(original))
	FileAccess.open(arg("--output=").get_base_dir()+"/after.json",FileAccess.WRITE).store_string(JSON.stringify(captured))
	inspect_types(original,captured,"world")
	check(var_to_bytes(Replay._canonical_data(original))==var_to_bytes(Replay._canonical_data(captured)),"Native development snapshot retains exact old canonical wire values/types")
	var broken: Dictionary=body.duplicate(true);broken.run.cash_cents=str(int(broken.run.cash_cents)+1)
	check(not validator._validate_payload(broken).is_empty(),"Warm proof rejects cash/finance drift")
	broken=body.duplicate(true);broken.rival_world.studios[0].policy.beta_hands="13"
	check(not validator._validate_payload(broken).is_empty(),"Warm proof rejects policy bound drift")
	broken=body.duplicate(true);broken.rival_world.source_identity="unknown"
	check(not validator._validate_payload(broken).is_empty(),"Warm proof rejects unknown source")
	var valid: Dictionary=Book.details(world.market_snapshot,str(r._bank_run_id),&"action")
	check(Book.valid_details(valid,&"action") and Book.valid_details(valid,&"action"),"Exact warm Book details")
	broken=valid.duplicate(true);broken.standards[0]+=1
	check(not Book.valid_details(broken,&"action"),"Warm Book proof rejects changed standards")
	broken=valid.duplicate(true);broken.cycle_start=float(broken.cycle_start)
	check(not Book.valid_details(broken,&"action"),"Warm Book proof preserves exact types")
	check(StudioFinanceLedger._is_valid(r._studio_finance),"Warm current finance journal")
	broken=r._studio_finance.duplicate(true);broken.cash_cents+=1
	check(not StudioFinanceLedger._is_valid(broken),"Warm journal proof rejects altered cents")
	finish()
func finish() -> void:
	var report:={"checks":checks,"issues":issues,"source":Replay.source_identity()};FileAccess.open(arg("--output="),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("QUALITY_CACHE "+JSON.stringify(report));quit(0 if issues.is_empty() else 1)

func inspect_types(a: Variant,b: Variant,path: String) -> void:
	if typeof(a)!=typeof(b):print("TYPE_DIFF "+path+" "+str(typeof(a))+"/"+str(typeof(b)));return
	if a is Dictionary:
		for key: Variant in a:
			if b.has(key):inspect_types(a[key],b[key],path+"/"+str(key))
	elif a is Array:
		if a.is_typed()!=b.is_typed():print("ARRAY_DIFF "+path+" "+str(a.is_typed())+"/"+str(b.is_typed()))
		for i in mini(a.size(),b.size()):inspect_types(a[i],b[i],path+"/"+str(i))
