"""Real preceding-world fixture and exact restored-state compatibility check."""
from pathlib import Path
import argparse, importlib.util
HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('save_tutorial_checks', HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c = importlib.util.module_from_spec(spec)
spec.loader.exec_module(c)
c.RAW = Path('C:/Users/64jus/AppData/Local/Temp/pn-save-tutorial-20261024-v1')
parser = argparse.ArgumentParser()
parser.add_argument('mode', choices=['prior', 'cold'])
args = parser.parse_args()
project = c.RAW/('red' if args.mode == 'prior' else 'green')/'project'
before = c.sim.source_hashes(project)
extra = [] if args.mode == 'prior' else ['--input='+str(c.RAW/'prior/result.json')]
result = c.run(args.mode, project, HERE.parent/'store-prerequisite-links-20261024-v1/world_probe.gd', extra, reuse=True)
assert c.sim.source_hashes(project) == before
raise SystemExit(0 if result['pass'] else 1)
