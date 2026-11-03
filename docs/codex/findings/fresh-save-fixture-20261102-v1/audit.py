from pathlib import Path
import json,re,sys,hashlib
b=Path(__file__).resolve().parent
root=Path.cwd();sys.path.insert(0,str(root/"tools"));import simulate
checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
 print("PASS:",label)
positive={"delay-green":8,"radial-headless":255,"radial-native":255,"loading-headless":18,"loading-native":18,"focus-native":22,"pair-final":4}
current=simulate.source_hashes(root/"patch-notes")
for name,count in positive.items():
 r=json.loads((b/name/"receipt.json").read_text(encoding="utf-8"));log=(b/name/"godot.log").read_text(encoding="utf-8")
 check(r["exit"]==0 and not r["errors"],name+" exits cleanly")
 check(all(r[k] for k in ["source_unchanged","harness_unchanged","fixture_unchanged"]),name+" keeps all fences")
 check(sum(x.startswith("PASS: ") for x in log.splitlines())==count and "FAIL: " not in log,name+" expected checks")
 observed=json.loads((b/name/"source-after.json").read_text(encoding="utf-8"))
 delta=[k for k in set(observed)|set(current) if observed.get(k)!=current.get(k)]
 check(delta in [[],["scripts/debug/verify_new_save_loading.gd"]],name+" exact final inventory or sole original LF restoration")
 if delta:
  before=(b/"before/patch-notes/scripts/debug/verify_new_save_loading.gd").read_bytes()
  after=(root/"patch-notes/scripts/debug/verify_new_save_loading.gd").read_bytes()
  check(b"\r\n" not in before and b"\r\n" not in after,"Loading fixture original LF preserved")
  check(observed[delta[0]]==hashlib.sha256(after.replace(b"\n",b"\r\n")).hexdigest(),name+" difference is exactly CRLF versus LF, same executable source")
red=json.loads((b/"delay-red/receipt.json").read_text(encoding="utf-8"));log=(b/"delay-red/godot.log").read_text(encoding="utf-8")
check(red["exit"]!=0 and "INJECTED_INITIAL_PUBLICATION_DELAY_MS=21000" in log and "Assertion failed: New-save transition timed out" in log,"Controlled initial-publication delay reproduces original limit")
green=json.loads((b/"delay-green/result.json").read_text(encoding="utf-8"));check(green["failures"]==0 and green["elapsed_ms"]>=21000,"Same delayed real save completes under new bound")
for mode,name in [("stuck","guard-timeout-strict"),("wrong-phase","guard-wrong-phase")]:
 r=json.loads((b/name/"receipt.json").read_text(encoding="utf-8"));log=(b/name/"godot.log").read_text(encoding="utf-8")
 check(r["exit"]!=0 and r["stop_reason"]=="script_error" and len(r["errors"])==1 and "EXPECTED_FIXTURE_GUARD="+mode in log,name+" records expected single assertion, not a pass")
 check(all(r[k] for k in ["source_unchanged","harness_unchanged","fixture_unchanged"]),name+" fences intact")
 if mode=="stuck":
  match=re.search(r"timed out after(\d+)ms",log);check(match and 60000<=int(match[1])<62000,"Stuck transition still fails at bounded60s deadline")
 else:check("finish_new_save" in log and "Assertion failed." in log,"Finished wrong phase is still rejected")
before=json.loads((b/"baseline-focus-native/source-before.json").read_text(encoding="utf-8"))
delta=sorted(k for k in before.keys()|current.keys() if before.get(k)!=current.get(k))
check(delta==["scripts/debug/ui_test_actions.gd","scripts/debug/verify_feature_store_radial.gd","scripts/debug/verify_new_save_loading.gd"],"Exactly three debug files changed; runtime, data, resources and source admission unchanged")
check(current==json.loads((b/"loading-native/source-after.json").read_text(encoding="utf-8")),"Final native acceptance matches entire current source")
pair=json.loads((b/"pair-final/result.json").read_text(encoding="utf-8"));original=json.loads((root/"docs/codex/findings/store-center-square-20261102-v1/pair-outline-final/result.json").read_text(encoding="utf-8"))
check(pair["player"]==original["player"] and pair["world"]==original["world"],"Genuine paired player/world and RNG equal byte-for-typed data including runtime identity")
check((root/"patch-notes/.codex-godot-temp").is_dir(),"Protected temporary workspace preserved")
result={"checks":checks,"failures":0,"source_delta":delta,"runtime_identity":pair["world"]["source_identity"],"positive_checks":positive,"negative_guard_cases":2}
(b/"audit-result.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
print(json.dumps(result))
