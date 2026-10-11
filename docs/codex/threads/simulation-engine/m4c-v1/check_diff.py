"""Check changed maintained files and the milestone's human-facing documents."""
from pathlib import Path
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
before = json.loads((HERE / 'before-hashes.json').read_text())
after = json.loads((HERE / 'after-hashes.json').read_text())
source = [name for name, digest in after.items() if before.get(name) != digest]
docs = ['docs/codex/CURRENT_STATE.md', 'docs/codex/README.md',
        *['docs/codex/threads/simulation-engine/' + name for name in [
            'README.md', 'USAGE.md', '2026-10-11-extraction-m4c.md',
            '2026-10-11-session-log-v12.md', 'examples/store-study.md', 'examples/store-prefix.json']]]
paths = sorted(set(source + docs))
argv = ['git', 'diff', '--check', '--', *paths]
result = subprocess.run(argv, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
bad = []
missing_links = []
for name in paths:
    for number, line in enumerate((ROOT / name).read_text(encoding='utf-8').splitlines(), 1):
        if line.endswith((' ', '\t')): bad.append(f'{name}:{number}')
    if name.startswith('docs/codex/threads/simulation-engine/') and name.endswith('.md'):
        for link in re.findall(r'\]\(([^)]+)\)', (ROOT / name).read_text(encoding='utf-8')):
            if '://' not in link and not link.startswith('#') and not (ROOT / name).parent.joinpath(link.split('#')[0]).exists(): missing_links.append(f'{name}: {link}')
report = {'ok': result.returncode == 0 and not bad and not missing_links, 'argv': argv,
          'exit': result.returncode, 'stdout': result.stdout.decode(errors='replace'),
          'stderr': result.stderr.decode(errors='replace'), 'trailing_whitespace': bad,
          'missing_local_links': missing_links, 'files': paths}
(HERE / 'diff-check.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps({key: report[key] for key in ['ok', 'exit', 'trailing_whitespace', 'missing_local_links']}, indent=2))
raise SystemExit(0 if report['ok'] else 1)
