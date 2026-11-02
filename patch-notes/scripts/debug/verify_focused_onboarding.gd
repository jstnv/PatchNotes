extends SceneTree
var checks:=0
var failures:=0
func expect(value: bool,label: String) -> void:
 checks+=1;print("PASS: " if value else "FAIL: ",label)
 if not value:failures+=1
func _initialize() -> void:verify.call_deferred()
func verify() -> void:
 expect(ResourceLoader.exists("res://scripts/tutorial/focused_guidance_catalog.gd"),"Focused conditional invitation catalog exists")
 if failures:quit(1);return
 var catalog=load("res://scripts/tutorial/focused_guidance_catalog.gd")
 var s={"releases":0,"public_releases":0,"bankroll_cents":100,"publishers":[],"implementation_engine":&"","skill_engine":&""}
 expect(catalog.candidates(s).is_empty(),"Fresh Studio has no premature unlock prompts")
 s.releases=1
 expect(ids(catalog.candidates(s)).has(&"contracts"),"First release offers Contracts independent of cash")
 expect(not ids(catalog.candidates(s)).has(&"employees"),"Employees waits for two releases")
 s.releases=2;s.bankroll_cents=-1;s.public_releases=2
 var offers: Array=catalog.candidates(s)
 expect(offers[0].id==&"bank","Negative signed bankroll takes priority")
 expect(ids(offers).has(&"employees") and not ids(offers).has(&"engines"),"Second release offers Employees but not premature public-engine tour")
 s.public_releases=3
 expect(ids(catalog.candidates(s)).has(&"engines"),"Three recorded Public releases offer Engines")
 s.bankroll_cents=0
 expect(not ids(catalog.candidates(s)).has(&"bank"),"Zero bankroll does not count as negative")
 s.implementation_engine=&"owned";s.skill_engine=&"owned";s.publishers=[&"ironclad"]
 expect(ids(catalog.candidates(s)).has(&"implementation") and ids(catalog.candidates(s)).has(&"skills") and ids(catalog.candidates(s)).has(&"publishers"),"Owned engine and earned skill/publisher unlocks have invitations")
 var Pref=load("res://scripts/tutorial/focused_guidance_preferences.gd")
 var path:=OS.get_environment("PN_FOCUS_TEST_DIRECTORY").path_join("preferences.cfg")
 var prefs=Pref.new(path)
 expect(not prefs.seen("studio-a",&"bank"),"New per-Studio acknowledgment defaults unseen")
 expect(prefs.mark("studio-a",&"bank") and prefs.seen("studio-a",&"bank"),"Dismissed/shown invitation is remembered")
 var reopened=Pref.new(path)
 expect(reopened.seen("studio-a",&"bank") and not reopened.seen("studio-b",&"bank"),"Preference survives reopen without leaking to another Studio")
 expect(not prefs.mark("studio-a",&"unknown"),"Unknown preference topic is rejected")
 print("EXPECTED_CORRUPT_FOCUSED_PREFERENCE")
 var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string("corrupt=[");f.close()
 expect(not Pref.new(path).seen("studio-a",&"bank"),"Corrupt preference safely falls back")
 var failed=Pref.new(path.path_join("missing/child.cfg"))
 expect(not failed.mark("studio-a",&"bank") and failed.seen("studio-a",&"bank"),"Failed persistence does not repeat the same invitation during this session")
 print("FOCUSED_CATALOG checks=%d failures=%d"%[checks,failures]);quit(failures)
func ids(items: Array) -> Array:
 return items.map(func(item: Dictionary):return item.id)
