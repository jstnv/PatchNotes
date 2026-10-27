"""Sequential stages; a failed bound stops the declared experiment."""
from pathlib import Path
import subprocess,sys
for stage in ['second','caps','recovery','readiness']:
    result=subprocess.run([sys.executable,'-X','utf8',str(Path(__file__).with_name('legal.py')),stage])
    if result.returncode:sys.exit(result.returncode)
