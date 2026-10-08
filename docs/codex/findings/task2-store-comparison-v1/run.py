"""Execute the predeclared read-only matrix against the private source snapshot."""
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import argparse
import gzip
import hashlib
import itertools
import json
import os
import subprocess
import time

OUT = Path(__file__).resolve().parent
META = json.loads((OUT/"source-manifest.json").read_text())
PROJECT = Path(META["project"])
WORK = PROJECT.parent
RAW = WORK / "raw"
RAW.mkdir(exist_ok=True)
(OUT/"traces").mkdir(exist_ok=True)
GODOT = Path(r"C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe")
DRIVER = PROJECT / "analysis/task2_analysis/driver.gd"
HARNESS_HASH = hashlib.sha256(b"".join((DRIVER.parent/name).read_bytes() for name in ("driver.gd","trial_run_state.gd","task29_base.gd"))).hexdigest()
PROCESS_TIMEOUT = 600
JOBS = []

def add(band, specialty, seed, policy, startup, store, timing, parent="none", fee=0):
    key = f"{band}_{specialty}_{seed}_{policy}_{startup}_{store}_{timing}_{parent}_{fee}"
    JOBS.append(dict(key=key, band=band, specialty=specialty, seed=seed, policy=policy, startup=startup, store=store, timing=timing, parent=parent, fee=fee))

def arms(band, specialty, seed, policy, startup):
    add(band, specialty, seed, policy, startup, "none", "none")
    for store, timing in itertools.product(("sub_areas", "background"), ("immediate", "buffer", "stronger_settled")):
        add(band, specialty, seed, policy, startup, store, timing)
    add(band, specialty, seed, policy, startup, "existing_sound" if specialty == "sports" else "existing_value", "immediate")

for specialty, seed, policy, startup in itertools.product(("action", "adventure", "strategy", "sports"), (1104,4417,2203), ("ordinary","synergy"), ("legacy","trait")):
    arms("early", specialty, seed, policy, startup)
for specialty, policy, startup in itertools.product(("action", "adventure"), ("ordinary","synergy"), ("legacy","trait")):
    arms("slow", specialty, 1104, policy, startup)
for policy, startup, timing in itertools.product(("ordinary","synergy"), ("legacy","trait"), ("immediate","buffer","stronger_settled")):
    add("early", "strategy", 1104, policy, startup, "sub_areas", timing, "levels")
for specialty, seed, policy, startup, timing in itertools.product(("action","strategy","adventure","sports"), (1104,4417), ("ordinary","synergy"), ("legacy","trait"), ("immediate","buffer","stronger_settled")):
    store, fee = ("sub_areas",9000) if specialty in ("action","strategy") else ("background",5000)
    add("early", specialty, seed, policy, startup, store, timing, fee=fee)
assert len(JOBS) == 556 and len({j["key"] for j in JOBS}) == 556

def sha(data): return hashlib.sha256(data).hexdigest()

def compact(data):
    def state(s):
        return {k:v for k,v in s.items() if k not in ("finance", "finance_report")}
    for action in data["actions"] + data["purchases"]:
        for k in ("before", "after"):
            if k in action: action[k] = state(action[k])
    data["live_cycles"] = [state(x) for x in data["live_cycles"]]
    for k in ("initial", "final"):
        data[k] = state(data[k])
    data["finance_observations"] = []
    data["studio_visits"] = []
    for k in list(data):
        if k.startswith("ironclad") or k.startswith("sidestreet_"): del data[k]
    return data

def run(job):
    key = job["key"]
    index = RAW / f"{key}.result.json"
    if index.exists():
        old = json.loads(index.read_text())
        if old.get("harness_sha256") == HARNESS_HASH and old["exit"] == 0 and old["valid"] and not old["errors"]: return old
    profile = WORK/"profiles"/key
    env = os.environ.copy()
    for name in ("APPDATA", "LOCALAPPDATA"):
        folder = profile/name
        folder.mkdir(parents=True, exist_ok=True)
        env[name] = str(folder)
    destination = RAW / f"{key}.json"
    if destination.exists():
        prior = destination.read_bytes()
        (RAW/f'{key}.unaccepted-before-retry.json.gz').write_bytes(gzip.compress(prior, mtime=0))
        destination.unlink()
    cmd = [str(GODOT), "--headless", "--path", str(PROJECT), "--script", str(DRIVER), "--", f"--out={destination}"]
    cmd.extend(f"--{k}={v}" for k,v in job.items())
    started = time.monotonic()
    try:
        result = subprocess.run(cmd, env=env, capture_output=True, timeout=PROCESS_TIMEOUT)
        code = result.returncode
        log = result.stdout + result.stderr
        deadline_error = []
    except subprocess.TimeoutExpired as expired:
        code = 124
        log = (expired.stdout or b'') + (expired.stderr or b'')
        deadline_error = [f'Process deadline exceeded {PROCESS_TIMEOUT} seconds; not an accepted native route.']
    (RAW/f"{key}.log").write_bytes(log)
    errors = deadline_error + [s for s in log.decode(errors="replace").splitlines() if "SCRIPT ERROR" in s or "FAIL:" in s or ("ERROR:" in s and "Failed to read the root certificate store." not in s)]
    record = dict(job=job, command=cmd, exit=code, errors=errors, elapsed_seconds=round(time.monotonic()-started,3), valid=False, harness_sha256=HARNESS_HASH)
    if destination.exists() and not deadline_error:
        raw = destination.read_bytes()
        data = json.loads(raw)
        record.update(valid=data["valid"], releases=len(data["releases"]), stop=data["stop"], discrepancies=data["discrepancies"], raw_sha256=sha(raw))
        (RAW/f"{key}.json.gz").write_bytes(gzip.compress(raw, mtime=0))
        small = json.dumps(compact(data), separators=(",", ":")).encode()
        record["compact_sha256"] = sha(small)
        (OUT/"traces"/f"{key}.json.gz").write_bytes(gzip.compress(small, mtime=0))
        destination.unlink()
    index.write_text(json.dumps(record, indent=2))
    return record

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--pilot", action="store_true")
    parser.add_argument("--workers", type=int, default=3)
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--recover-slow", action="store_true")
    opt = parser.parse_args()
    PROCESS_TIMEOUT = opt.timeout
    (OUT/"manifest.json").write_text(json.dumps(dict(source_head=META["head"], jobs=JOBS, driver_sha256=sha(DRIVER.read_bytes()), subclass_sha256=sha((DRIVER.parent/"trial_run_state.gd").read_bytes()), base_sha256=sha((DRIVER.parent/"task29_base.gd").read_bytes()), harness_sha256=HARNESS_HASH, count=len(JOBS)), indent=2))
    jobs = [j for j in JOBS if j["seed"] == 1104 and j["policy"] == "ordinary" and j["startup"] == "legacy" and j["band"] == "early" and ((j["store"] == "sub_areas" and j["timing"] == "buffer") or (j["store"] == "background" and j["timing"] == "immediate" and j["fee"] in (0,5000)))] if opt.pilot else JOBS
    if opt.recover_slow:
        jobs = [j for j in jobs if j['band'] == 'slow']
    records = []
    with ThreadPoolExecutor(max_workers=opt.workers) as pool:
        futures = {pool.submit(run,j):j for j in jobs}
        for future in as_completed(futures):
            item = future.result()
            records.append(item)
            print(len(records),"/",len(jobs),item["job"]["key"], item["exit"],item["valid"],item.get("releases"),flush=True)
            if item["exit"] or not item["valid"] or item["errors"]:
                print(item,flush=True)
    index_name = 'retry-slow-index.json' if opt.recover_slow else 'pilot-index.json' if opt.pilot else 'run-index.json'
    (OUT/index_name).write_text(json.dumps(sorted(records,key=lambda r:r["job"]["key"]),indent=2))
    if any(item['exit'] or not item['valid'] or item['errors'] for item in records):
        raise RuntimeError('Invalid routes retained in the index; inspect and rerun before auditing completion')
    print("DONE",len(records),flush=True)
