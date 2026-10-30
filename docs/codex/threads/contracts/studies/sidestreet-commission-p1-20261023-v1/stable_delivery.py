from pathlib import Path
import json,sys,subprocess,hashlib
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
argv=json.loads((H/'delivery-v3.command.json').read_text())['argv']
argv[argv.index('--output')+1]=str(T/'sims/sidestreet-commission-p1-delivery-20261023-v3-stable1')
config=Path(argv[argv.index('--config')+1]);before=hashlib.sha256(config.read_bytes()).hexdigest()
todo=(R/'docs/codex/TODO.md').read_text(encoding='utf-8')
assert '**2026-10-23 Continue loading overlay — COMPLETE locally:**' in todo
with (H/'stable-window-authority.txt').open('x',encoding='utf-8') as f:f.write(todo.split('\n\n')[1])
p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
assert hashlib.sha256(config.read_bytes()).hexdigest()==before
with (H/'delivery-v3-stable1.command.json').open('x') as f:json.dump(dict(argv=argv,config_sha256=before,exit=p.returncode,stdout=p.stdout,stderr=p.stderr),f,indent=2)
print(p.stdout);print(p.stderr);sys.exit(p.returncode)
