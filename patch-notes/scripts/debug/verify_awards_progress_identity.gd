extends SceneTree
const Ledger:=preload("res://scripts/awards/annual_awards_ledger.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	for encoded in [false,true]:
		for stages in [[0,false,0,false,true],[9,true,0,false,true],[9,true,9,true,true],[0,false,9,true,false],[9,false,9,true,false],[8,true,0,false,false],[10,false,0,false,false],[-1,false,0,false,false]]:
			var state: Dictionary={"version":1,"entries":[{"stage":str(stages[0]) if encoded else stages[0],"complete":stages[1],"result":{"frozen":7}},{"stage":str(stages[2]) if encoded else stages[2],"complete":stages[3],"owners":["preserved"]}]}
			var before:=var_to_bytes(state)
			var identity:=Ledger.presentation_identity(state,encoded)
			check(not identity.is_empty()==stages[4],"Two-year completion-prefix predicate %s/%s"%[encoded,stages])
			check(var_to_bytes(state)==before,"Identity never mutates its source")
			if not identity.is_empty():
				check(identity.entries[0].result==state.entries[0].result and identity.entries[1].owners==state.entries[1].owners,"Frozen result and ownership survive projection")
		for value: Variant in (["01","1.0","-0",1,true,null,[],{}] if encoded else ["1",1.0,true,null,[],{}]):
			check(Ledger.presentation_identity({"entries":[{"stage":value,"complete":false}]},encoded).is_empty(),"Malformed progress type rejects: %s/%s"%[encoded,value])
		check(Ledger.presentation_identity({"entries":[{"stage":"1" if encoded else 1,"complete":"false"}]},encoded).is_empty(),"Malformed completion type rejects")
		check(Ledger.presentation_identity({"entries":[{"complete":false}]},encoded).is_empty(),"Missing stage rejects")
	check(Ledger.presentation_identity({}).is_empty(),"Missing entry array rejects")
	print("AWARDS_PROGRESS_IDENTITY checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
