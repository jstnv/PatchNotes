from pathlib import Path
import json,sys,subprocess,hashlib
from paths import bundle
H=Path(__file__).resolve().parent;R=H.parents[5]
original=json.loads((H/'delivery-v3.command.json').read_text())
argv=original['argv'];argv[argv.index('--output')+1]=str(bundle('delivery'))
config=Path(argv[argv.index('--config')+1]);before=hashlib.sha256(config.read_bytes()).hexdigest()
p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
assert hashlib.sha256(config.read_bytes()).hexdigest()==before
with (H/'delivery-v3-retry1.command.json').open('x') as f:json.dump(dict(argv=argv,config_sha256=before,exit=p.returncode,stdout=p.stdout,stderr=p.stderr),f,indent=2)
print(p.stdout);print(p.stderr);sys.exit(p.returncode)
