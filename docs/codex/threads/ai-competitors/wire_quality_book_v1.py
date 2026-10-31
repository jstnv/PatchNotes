from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v5/project'
def edit(path,old,new,count=1):
 f=P/path;s=f.read_text(encoding='utf-8');assert old in s,(path,old[:50]);f.write_bytes(s.replace(old,new,count).encode())
edit('scripts/market/rival_standard_book.gd','records.sort_custom(_before)','return build_records(records,target_cycle)\nstatic func build_records(records: Array,target_cycle: int) -> Dictionary:\n\tvar month:=target_cycle-target_cycle%2\n\trecords=records.filter(func(r: Dictionary)->bool:return r.release_cycle<month and r.release_cycle<72)\n\trecords.sort_custom(_before)')
edit('scripts/market/rival_standard_book.gd','''var market:=preload("res://scripts/market/market_transaction_trial.gd")
	return market.valid({"version":2,"cycle_start":value.cycle_start,"id":"market-0-neutral" if value.cycle_start==0 else market.identifier(value.cycle_start,value.facts),"facts":value.facts})''','''var previous:=""
	for row: Variant in value.facts:
		if not row is Dictionary or row.size()!=8:return false
		for key in ["studio_id","release_id","genre","theme"]:
			if not row.get(key) is String or row[key].is_empty():return false
		for key in ["release_cycle","review_tenths"]:
			if not row.get(key) is int or row[key]<0:return false
		if row.review_tenths>100 or row.release_cycle>=value.cycle_start or value.cycle_start-row.release_cycle>12 or not row.get("cores_available") is bool or not row.get("cores") is Array or row.cores.size()!=(4 if row.cores_available else 0):return false
		var key: String=row.studio_id+"/"+row.release_id
		if not previous.is_empty() and key<=previous:return false
		previous=key
		for core: Variant in row.cores:
			if not core is int or core<0:return false
	return value.cycle_start>0 or value.facts.is_empty()''')
edit('scripts/market/market_transaction_trial.gd','const Historical :=','const Book:=preload("res://scripts/market/rival_standard_book.gd")\nconst Historical :=')
edit('scripts/market/market_transaction_trial.gd','if snapshot is Dictionary and snapshot.get("version")==3:','if snapshot is Dictionary and snapshot.get("version")==4:return Book.valid_snapshot(snapshot)\n\tif snapshot is Dictionary and snapshot.get("version")==3:')
edit('scripts/market/market_transaction_trial.gd','result.id=identifier(target_cycle,facts)','if world.market_snapshot.version==4:return Book.snapshot(world.market_snapshot.basis,target_cycle,72,facts)\n\tresult.id=identifier(target_cycle,facts)')
edit('scripts/market/market_transaction_trial.gd','if snapshot.version==3: return Historical.details(snapshot,genre)','if snapshot.version==4:return Book.details(snapshot,studio_id,genre)\n\tif snapshot.version==3: return Historical.details(snapshot,genre)')
edit('scripts/market/market_transaction_trial.gd','if snapshot.version==3: return neutral_factor()','if snapshot.version==3 or (snapshot.version==4 and snapshot.epoch_offset==0): return neutral_factor()')
edit('scripts/market/market_transaction_trial.gd','var prefix := "market-v2-%d-"%cycle','var prefix := ("market-book-v1-%d-" if id.begins_with("market-book-v1-") else "market-v2-%d-")%cycle')
edit('scripts/market/market_transaction_trial.gd','static func valid_details(value: Variant, genre: StringName) -> bool:','static func valid_details(value: Variant, genre: StringName) -> bool:\n\tif value is Dictionary and str(value.get("snapshot_id","")).begins_with(Book.PREFIX):return Book.valid_details(value,genre)')
edit('scripts/project_state.gd','str(source_id).begins_with("historical-core-v2:")','(str(source_id).begins_with("historical-core-v2:") or str(source_id).begins_with("historical-book-v1:"))')
edit('scripts/persistence/studio_checkpoint.gd','"-careers1-preludeclose2"','"-careers1-preludeclose3-book1"')
f=P/'scripts/market/rival_world_checkpoint.gd';s=f.read_text(encoding='utf-8');s=s.replace('const Historical :=','const Book:=preload("res://scripts/market/rival_standard_book.gd")\nconst Historical :=',1)
start=s.index('static func _market_schema()');end=s.index('\nstatic func _origin_schema()',start)
old=s[start:end]
new='''static func _book_source_schema() -> Dictionary:
	return {"studio_id":"text","release_id":"text","release_cycle":"uint","review_tenths":"uint","genre":"text","cores":CheckpointSchema.array_of("uint")}
static func _market_schema() -> Dictionary:
	var ordinary: Dictionary={"version":"uint","cycle_start":"uint","id":"text","facts":CheckpointSchema.array_of({"studio_id":"text","release_id":"text","release_cycle":"uint","genre":"text","theme":"text","review_tenths":"uint","cores_available":"bool","cores":CheckpointSchema.array_of("uint")})}
	var book: Dictionary=ordinary.duplicate(true)
	book.epoch_offset="uint";book.basis=CheckpointSchema.map_of("text",{"first":_book_source_schema(),"benchmarks":CheckpointSchema.array_of(_book_source_schema())})
	return CheckpointSchema.union_of([ordinary,book])
'''
s=s[:start]+new+s[end:]
marker='owners.append_array(decoded_rows)';assert marker in s
s=s.replace(marker,marker+'''
	var book_records: Array=[]
	for owner: Dictionary in owners:
		if int(owner.get("offset",0))!=72:continue
		var data: Dictionary=StudioCheckpoint.new()._decode_payload(owner.run,not owner.development.is_empty()).get("run",{})
		for id: StringName in data.get("released_games",{}):
			var m: Dictionary=data.release_metadata[id]
			if m.release_cycle>=72:continue
			book_records.append({"studio_id":str(owner.id),"release_id":str(id),"release_cycle":int(m.release_cycle),"review_tenths":int(data.released_games[id].review_tenths),"genre":str(m.genre),"cores":m.review.cores.duplicate()})
	var full_basis:=Book.build_records(book_records,72)
	if not full_basis.is_empty():snapshots[0]=Book.snapshot(full_basis,0,72)
''',1)
marker='if str(d.snapshot_id).begins_with(Historical.PREFIX):';assert marker in s
s=s.replace(marker,'''if str(d.snapshot_id).begins_with(Book.PREFIX):
				var p:=Book.proof(d.snapshot_id)
				var begin_cycle: int=_historical_begin_cycle(native.run,StringName(item.get("project_id",&"")))
				if not Book.valid_details(d,item.genre) or p.owner!=str(owner.id) or (p.epoch_offset==0 and (begin_cycle>72 or begin_cycle<1)) or d.cycle_start!=(begin_cycle-int(p.epoch_offset))-(begin_cycle-int(p.epoch_offset))%2:error="Book project freeze boundary mismatch";return false
				var expected_basis: Dictionary=Book.build_records(book_records,int(d.cycle_start)+int(p.epoch_offset)).get(str(item.genre),{})
				var facts: Array=[] if p.epoch_offset==0 else _expected_market_facts(d,player_payload,encoded_rows)
				var expected: Dictionary=Book.details(Book.snapshot({str(item.genre):expected_basis} if not expected_basis.is_empty() else {},d.cycle_start,p.epoch_offset,facts),str(owner.id),item.genre)
				if expected!=d:error="Book dated source provenance mismatch";return false
				continue
			'''+marker,1)
s=s.replace('snapshots[d.cycle_start]={"version":Market.VERSION,"cycle_start":d.cycle_start,"facts":facts,"id":Market.identifier(d.cycle_start,facts)}','snapshots[d.cycle_start]=Book.snapshot(full_basis,d.cycle_start,72,facts) if not full_basis.is_empty() else {"version":Market.VERSION,"cycle_start":d.cycle_start,"facts":facts,"id":Market.identifier(d.cycle_start,facts)}',1)
# Current full snapshot is also pinned to every actual archived owner release.
marker='if not _validate_frozen_market(player_payload,payload.studios,rows,cycle,origin): return {}';assert marker in s
s=s.replace(marker,marker+'''
	if market.version==4 and not _book_matches_owners(market,rows):return {}
''',1)
s+='''
func _book_matches_owners(market: Dictionary,rows: Array) -> bool:
	var records: Array=[]
	for row: Dictionary in rows:
		var data: Dictionary=StudioCheckpoint.new()._decode_payload(row.run,not row.development.is_empty()).get("run",{})
		for id: StringName in data.get("closed_historical_ids",{}):
			var m: Dictionary=data.release_metadata[id]
			records.append({"studio_id":str(row.id),"release_id":str(id),"release_cycle":int(m.release_cycle),"review_tenths":int(data.released_games[id].review_tenths),"genre":str(m.genre),"cores":m.review.cores.duplicate()})
	if market.epoch_offset!=72 or market.basis!=Book.build_records(records,72):error="Unproven opening standard book";return false
	return true
'''
f.write_bytes(s.encode());print('Book wired with typed schema, dated owner provenance and unchanged active formulas.')
