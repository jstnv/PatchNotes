"""Temporary system-idle guard; does not change power settings or keep display on."""
from pathlib import Path
import ctypes
import datetime
import json
import time

here = Path(__file__).resolve().parent
stop = here / "keep-awake.stop"
assert not stop.exists(), "Use a fresh stop marker"
api = ctypes.windll.kernel32.SetThreadExecutionState
api.argtypes = [ctypes.c_uint]
api.restype = ctypes.c_uint
assert api(0x80000001), "System idle guard refused"
start = datetime.datetime.now(datetime.timezone.utc).isoformat()
print(json.dumps({"started_utc": start, "system_idle_required": True,
                  "settings_changed": False, "display_required": False}), flush=True)
try:
    deadline = time.monotonic() + 8 * 3600
    while not stop.exists() and time.monotonic() < deadline:
        time.sleep(5)
finally:
    released = bool(api(0x80000000))
    result = {"started_utc": start, "finished_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "released": released, "settings_changed": False}
    (here / "keep-awake-result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result), flush=True)
