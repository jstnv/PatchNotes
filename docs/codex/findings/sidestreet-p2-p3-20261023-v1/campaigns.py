"""Declared final sequence after the fresh prefix; stop on any failed bound."""
from pathlib import Path
import subprocess,sys
for stage in ['first','second','caps','recovery','readiness','zero']:
    outcome=subprocess.run([sys.executable,'-X','utf8',str(Path(__file__).with_name('legal.py')),stage])
    if outcome.returncode:raise SystemExit(outcome.returncode)
