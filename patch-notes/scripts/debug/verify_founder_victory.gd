extends SceneTree

const Victory := preload("res://scripts/legacy/victory_ledger.gd")
const Legacy := preload("res://scripts/legacy/legacy_world.gd")
const Founder := preload("res://scripts/legacy/founder_profile.gd")
const Ownership := preload("res://scripts/legacy/ownership_book.gd")

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL: "+label)

func _initialize() -> void:
	var founder := Founder.create("tester","root",0)
	var ledger := Victory.create(founder,0)
	check(Victory.valid(ledger,founder,[],0),"Empty victory ledger is valid and has no free claim")
	var books := {"root":Ownership.create("root",{"founder:tester":1000000})}
	for number in range(1,11):
		var id := "sub%d"%number
		var parent := "sub9" if number==10 else "root"
		books[id]=Ownership.create(id,{"studio:"+parent:1000000})
	books["tie"]=Ownership.create("tie",{"studio:root":500000,"outside:pool":500000})
	check(Ownership.valid_world(books),"Acyclic twelve-Studio corporate fixture validates")
	var expected := ["sub1","sub10","sub2","sub3","sub4","sub5","sub6","sub7","sub8","sub9"]
	check(Victory.controlled_subsidiaries(books,"tester")==expected,"Ten distinct majority subsidiaries include an indirect child but exclude a 50 percent tie")
	var partial := books.duplicate(true)
	partial.erase("sub10")
	partial["sub9"].transaction_ids.append("tx-9")
	var first_event := {"id":"tx-9","cycle":0,"target":"sub9","cash_legs":[]}
	var first := Victory.after_ownership_commit(ledger,founder,[first_event],partial,0,"tx-9")
	check(not first.is_empty() and not first.awarded and first.ledger.claims.is_empty(),"Nine subsidiaries do not claim")
	check(Victory.after_ownership_commit(ledger,founder,[first_event],books,0,"tx-10").is_empty(),"Missing committed transaction cannot claim")
	books["sub10"].transaction_ids.append("tx-10")
	var second_event := {"id":"tx-10","cycle":0,"target":"sub10","cash_legs":[]}
	var events := [first_event,second_event]
	check(Victory.after_ownership_commit(first.ledger,first.founder,events,books,0,"tx-9").is_empty(),"An older event cannot be replayed as the current commit")
	var awarded := Victory.after_ownership_commit(first.ledger,first.founder,events,books,0,"tx-10")
	check(not awarded.is_empty() and awarded.awarded and awarded.founder.milestone_ids==[Victory.SUBSIDIARY_CLAIM],"Tenth committed acquisition records one founder victory")
	if awarded.is_empty(): quit(1); return
	check(Victory.valid(awarded.ledger,awarded.founder,events,0),"Claim validates against transaction and frozen control graph")
	var again := Victory.after_ownership_commit(awarded.ledger,awarded.founder,events,books,0,"tx-10")
	check(not again.is_empty() and not again.awarded and again.ledger==awarded.ledger,"Repeated evaluation leaves the achievement once-only")
	var corrupt: Dictionary = awarded.ledger.duplicate(true)
	corrupt.claims[0].studio_ids.pop_back()
	check(not Victory.valid(corrupt,awarded.founder,events,0),"Corrupted subsidiary evidence rejects")
	corrupt=awarded.ledger.duplicate(true)
	corrupt.claims[0].books["sub10"].holders={"studio:root":500000,"outside:pool":500000}
	check(not Victory.valid(corrupt,awarded.founder,events,0),"Tampered majority proof rejects")
	check(not Victory.valid(awarded.ledger,founder,events,0),"Missing founder milestone rejects")
	var restored: Dictionary=Legacy._unwire(JSON.parse_string(JSON.stringify(Legacy._wire(awarded.ledger))))
	check(restored==awarded.ledger and Victory.valid(restored,awarded.founder,events,0),"Exact JSON ledger round trip preserves claim")
	print("Founder victory ledger: %d checks, %d failures"%[checks,failures])
	quit(failures)
