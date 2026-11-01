extends SceneTree

var checks := 0
var failures: Array[String] = []
var rules: Script

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func studio(id: String, fans: int = 100, gained: int = 20) -> Dictionary:
	return {"studio_id":StringName(id), "studio_name":"Studio " + id, "fans":fans, "gained_fans":gained}

func game(id: String, owner: String, cores: Array = [10,20,30,40], review: int = 80, cycle: int = 10, year: int = 1980) -> Dictionary:
	return {"release_id":StringName(id), "studio_id":StringName(owner), "title":"Game " + id, "cores":cores, "review_tenths":review, "release_cycle":cycle, "release_year":year}

func ids(award: Dictionary) -> Array:
	var result: Array = []
	for nominee in award.nominees: result.append(str(nominee.studio_id) + "/" + str(nominee.release_id))
	return result

func _initialize() -> void:
	await process_frame
	var path := "C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/docs/codex/findings/annual-awards-20261031-v1/rules-red-behavior/missing_rules.gd"
	check(ResourceLoader.exists(path), "Annual awards ranking exists and can produce an eligible winner")
	if ResourceLoader.exists(path):
		rules = load(path)
		if rules != null: run_checks()
	print("ANNUAL_AWARDS_RULES checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func run_checks() -> void:
	var empty: Dictionary = rules.rank(1980,45,[],[])
	check(empty.get("awards",[]).size() == 7 and empty.get("rewards",[1]).is_empty(), "Empty cohort has seven sparse awards and zero gifts")
	for award in empty.get("awards",[]): check(award.nominees.is_empty(), "Empty " + str(award.id) + " has no fabricated winner")
	var owners := [studio("a"),studio("b",900,100),studio("idle",9999,999)]
	var releases := [game("a1","a")]
	var before_owners: Array = owners.duplicate(true)
	var before_releases: Array = releases.duplicate(true)
	var one: Dictionary = rules.rank(1980,45,owners,releases)
	check(one.get("awards",[]).size() == 7, "A sole eligible game receives seven real first places")
	if one.is_empty(): return
	check(one.rewards == [{"studio_id":&"a","nominations":7,"wins":7,"fans":350,"awareness":35}], "Repeat wins stack seven nomination and win gifts exactly")
	for award in one.awards:
		check(award.nominees.size() == 1 and award.nominees[0].studio_id == &"a" and award.nominees[0].rank == 1, "Only released Studio eligible for " + str(award.id))
	check(owners == before_owners and releases == before_releases, "Ranking leaves caller inputs unchanged")
	one.games[0].cores[0] = 999
	check(releases[0].cores == [10,20,30,40], "Frozen output has no nested caller aliases")
	var two: Dictionary = rules.rank(1980,45,[studio("b"),studio("a")],[game("b1","b"),game("a1","a")])
	check(two.awards[0].nominees.size() == 2 and ids(two.awards[0]) == ["a/a1","b/b1"], "Two contenders leave third position empty and use textual Studio tie")
	var many_owners := [studio("c"),studio("b"),studio("a"),studio("d")]
	var many_games := [game("c1","c"),game("b1","b"),game("a2","a"),game("a1","a"),game("d1","d")]
	var many: Dictionary = rules.rank(1980,45,many_owners,many_games)
	check(ids(many.awards[0]) == ["a/a1","a/a2","b/b1"], "Four-plus games nominate only three using Studio then release ties")
	check(ids(many.awards[4]) == ["a/","b/","c/"], "Studio awards deduplicate multiple eligible games and nominate only three")
	check(many.rewards == [{"studio_id":&"a","nominations":12,"wins":7,"fans":400,"awareness":35},{"studio_id":&"b","nominations":7,"wins":0,"fans":70,"awareness":0},{"studio_id":&"c","nominations":2,"wins":0,"fans":20,"awareness":0}], "Multiple games and Studio nominations produce independently hand-counted totals")
	many_owners.reverse();many_games.reverse()
	check(rules.rank(1980,45,many_owners,many_games) == many, "Every frozen result array is independent of input iteration order")
	var distinct := [game("g1","a",[90,1,1,1],81),game("g2","b",[1,90,1,1],82),game("g3","c",[1,1,90,90],83)]
	var score_result: Dictionary = rules.rank(1980,45,[studio("a",900,1),studio("b",1,900),studio("c",2,2)],distinct)
	check(ids(score_result.awards[0])[0] == "a/g1" and ids(score_result.awards[1])[0] == "b/g2" and ids(score_result.awards[2])[0] == "c/g3" and ids(score_result.awards[3])[0] == "c/g3", "Four category awards use their own exact Core")
	check(ids(score_result.awards[4])[0] == "b/" and ids(score_result.awards[5])[0] == "a/", "Rising uses gross gained Fans and Studio uses current pre-award Fans")
	check(ids(score_result.awards[6]) == ["c/g3","b/g2","a/g1"] and score_result.awards[6].nominees[0].score == 83, "GOTY uses exact Review tenths without rounding")
	distinct[0].sales = 9223372036854775807;distinct[2].sales = 0
	check(rules.rank(1980,45,[studio("a",900,1),studio("b",1,900),studio("c",2,2)],distinct) == score_result, "Sales metadata cannot influence score, tie, or frozen result")
	var filtered: Dictionary = rules.rank(1980,45,owners,[game("old","b",[999,999,999,999],100,1,1979),game("future","b",[999,999,999,999],100,46),game("nextyear","b",[999,999,999,999],100,1,1981),game("cutoff","a",[1,1,1,1],1,45)])
	check(filtered.games.size() == 1 and filtered.games[0].release_id == &"cutoff" and filtered.rewards[0].studio_id == &"a", "Current year and inclusive committed cutoff exclude stronger old/future games")
	var bounds: Dictionary = rules.rank(1980,45,[studio("a",9223372036854775457,9223372036854775807)],[game("a1","a",[9223372036854775807,0,0,0],100)])
	check(not bounds.is_empty() and bounds.awards[0].nominees[0].score == 9223372036854775807, "Maximum exact scores and maximum safe post-gift Fans remain integer")
	check(rules.rank(1980,45,[studio("a",9223372036854775458)],[game("a1","a")]).is_empty(), "Fan reward addition overflow rejects whole plan")
	var bad_cases: Array = [
		[[],[game("orphan","missing")]],
		[[studio("a"),studio("a")],[]],
		[[studio("a")],[game("same","a"),game("same","a")]],
		[[{"studio_id":&"a","studio_name":"A","fans":1.0,"gained_fans":0}],[]],
		[[studio("a",-1)],[]],
		[[studio("")],[]],
		[[studio("a")],[game("bad","a",[1,2,3])]],
		[[studio("a")],[game("bad","a",[1,2,3,4.0])]],
		[[studio("a")],[game("bad","a",[1,2,3,-1])]],
		[[studio("a")],[game("bad","a",[1,2,3,4],101)]],
		[[studio("a")],[game("bad","a",[1,2,3,4],-1)]],
		[[studio("a")],[game("bad","a",[1,2,3,4],80,-1)]],
		[[studio("a")],[{}]],
		[[null],[]],
	]
	for index in range(bad_cases.size()):
		check(rules.rank(1980,45,bad_cases[index][0],bad_cases[index][1]).is_empty(), "Malformed/duplicate input rejects atomically case " + str(index))
	check(rules.rank(1979,45,[],[]).is_empty() and rules.rank(1980,-1,[],[]).is_empty(), "Unsupported annual year or negative cutoff rejects")
	var codec := CheckpointCodec.new()
	var encoded: Variant = codec.encode(score_result,rules.schema())
	check(codec.error.is_empty() and encoded != null, "Result schema encodes frozen rankings")
	var decoded: Variant = codec.decode(encoded,rules.schema())
	check(codec.error.is_empty() and decoded == score_result, "Result schema round trips exact native IDs and integers")
