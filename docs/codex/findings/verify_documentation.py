"""Validate shared-context hierarchy, task coverage, links and runtime preservation."""
from pathlib import Path
import hashlib, json, re, subprocess
ROOT = Path(__file__).resolve().parents[3]
DOCS = ROOT / 'docs/codex'
OUT = DOCS / 'findings/migration-2026-10-06'

if __name__ == '__main__':
    checks = {}
    missing = []
    for path in [ROOT / 'AGENTS.md', *DOCS.rglob('*.md')]:
        body = path.read_text(encoding='utf-8')
        for target in re.findall(r'\]\(([^)]+)\)', body):
            if target.startswith(('https://', 'http://', 'codex://', '#')):
                continue
            target = target.split('#')[0].strip('<>')
            if not (path.parent / target).exists():
                missing.append({'file': str(path.relative_to(ROOT)), 'target': target})
    checks['relative_links_valid'] = not missing
    todo = (DOCS / 'TODO.md').read_text(encoding='utf-8')
    ids = [int(x) for x in re.findall(r'^\|(\d+)\|', todo, re.M)]
    checks['all_34_task_ids_once'] = sorted(ids) == list(range(1, 35))
    required = ['CURRENT_STATE.md', 'TODO.md', 'DECISIONS.md', 'README.md', 'design', 'findings', 'logs', 'archive']
    checks['context_hierarchy_present'] = all((DOCS / p).exists() for p in required)
    source = (DOCS / 'archive/drive-task-queue-2026-10-06.txt').read_text(encoding='utf-8')
    source_ids = [int(x) for x in re.findall(r'^TASK (\d+) —', source, re.M)]
    checks['queue_snapshot_has_all_34_tasks'] = source_ids == list(range(1,35))
    baseline = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))['runtime_sha256']
    current = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
               for folder in ['scripts', 'scenes', 'data'] for p in (ROOT / 'patch-notes' / folder).rglob('*') if p.is_file()}
    checks['runtime_files_still_unchanged'] = current == baseline
    diff = subprocess.run(['git', 'diff', '--check'], cwd=ROOT, capture_output=True)
    checks['git_diff_check'] = diff.returncode == 0
    # Existing untracked documentation is not checked by git diff --check.
    whitespace = []
    for path in [ROOT / 'AGENTS.md', *DOCS.rglob('*.md'), *DOCS.rglob('*.py')]:
        for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
            if line.rstrip() != line:
                whitespace.append(str(path.relative_to(ROOT)) + ':' + str(number))
    checks['new_documentation_whitespace'] = not whitespace
    result = {'checks': checks, 'missing_links': missing, 'whitespace': whitespace,
              'git_diff_check_output': (diff.stdout + diff.stderr).decode(errors='replace'),
              'state_words': len((DOCS/'CURRENT_STATE.md').read_text(encoding='utf-8').split()),
              'new_files': ['AGENTS.md'] + sorted(str(p.relative_to(ROOT)) for p in DOCS.rglob('*') if p.is_file() and '__pycache__' not in str(p)),
              'passed': all(checks.values())}
    (OUT / 'documentation-sanity.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k!='new_files'}, indent=2))
    raise SystemExit(0 if result['passed'] else 1)
