"""Pin the approved runtime and materialize the bounded study before execution."""
from pathlib import Path
import datetime as dt
import hashlib
import importlib.util
import json
import subprocess
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("cult_simulate", ROOT / "tools/simulate.py")
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
hashes = {name:sim.sha(path) for name,path in sim.source_files(ROOT / "patch-notes").items()}
sim.write_json(HERE / "source-before.json",hashes)
git = {}
for name,args in {"branch":["branch","--show-current"],"head":["rev-parse","HEAD"],"status":["status","--short"],"diff":["diff","--stat"]}.items():
    result = subprocess.run(["git",*args],cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True)
    git[name] = result.stdout.strip()
sim.write_json(HERE / "provenance.json", {"created_utc":dt.datetime.now(dt.timezone.utc).isoformat(),"source_identity":hashlib.sha256(json.dumps(hashes,sort_keys=True).encode()).hexdigest(),"git":git,"plan_sha256":sim.sha(HERE / "PLAN.md"),"policy_sha256":sim.sha(HERE / "policy.gd")})
hands = [{"design":5,"alpha":6,"beta":6},{"design":1,"alpha":1,"beta":1},{"design":5,"alpha":6,"beta":6},{"design":2,"alpha":2,"beta":2},{"design":1,"alpha":1,"beta":1}]
for gate,builds in [("solo",{"control":[],"cult":["cult_following"],"buzz":["studio_buzz"],"family":["family_funding"]}),("interaction",{"cult-buzz":["cult_following","studio_buzz"],"cult-lease":["cult_following","expensive_lease"],"lease":["expensive_lease"]})]:
    cases = []
    for seed in [4417,1104]:
        for arm,traits in builds.items():
            case_id = f"post-{seed}-{arm}"
            cases.append({"schema_version":"1","case_id":case_id,"initial":{"recipe":{"schema_version":1,"studio_id":case_id,"studio_name":f"Cult post {arm} {seed}","specialty":"action","traits":traits,"seed":str(seed)}},"max_commands":140,"target_release_count":5,"telemetry":True,"policy":{"config":{"hands_by_release":hands,"cycle_cap":53}}})
    sim.write_json(HERE / (gate + ".json"),{"schema_version":"1","policy":{"script":"policy.gd","id":"cult-post-adoption-read-only","version":"1"},"cases":cases})
print(json.dumps({"prepared":True,"cases":14,"source_identity":hashlib.sha256(json.dumps(hashes,sort_keys=True).encode()).hexdigest(),"policy_sha256":sim.sha(HERE / "policy.gd")}))
