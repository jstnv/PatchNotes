"""Inspect the staged delivery without exposing credential-like contents."""
from pathlib import Path
import collections
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent


def git(*args):
    return subprocess.check_output(['git', '-c', 'core.longpaths=true', *args], cwd=ROOT)


def main():
    changed = {x.decode() for x in git('diff', '--cached', '--name-only', '-z').split(b'\0') if x}
    entries = []
    for row in git('ls-files', '--stage', '-z').split(b'\0'):
        if not row:
            continue
        info, path = row.decode().split('\t', 1)
        if path in changed:
            mode, oid, stage = info.split()
            assert stage == '0', path
            entries.append((oid, path))
    objects = collections.defaultdict(list)
    for oid, path in entries:
        objects[oid].append(path)
    patterns = {
        'private_key': rb'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----',
        'github_token': rb'gh[pousr]_[A-Za-z0-9]{36,}',
        'github_fine_grained_token': rb'github_pat_[A-Za-z0-9_]{70,}',
        'openai_key': rb'sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{40,}',
        'aws_access_id': rb'(?<![A-Za-z0-9])AKIA[0-9A-Z]{16}(?![A-Za-z0-9])',
    }
    compiled = {name: re.compile(pattern) for name, pattern in patterns.items()}
    suspicious = []
    sizes = []
    byte_changes = []
    pipe = subprocess.Popen(['git', 'cat-file', '--batch'], cwd=ROOT,
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    try:
        for oid, paths in objects.items():
            pipe.stdin.write((oid + '\n').encode()); pipe.stdin.flush()
            header = pipe.stdout.readline().split()
            assert header[1] == b'blob', header
            size = int(header[2]); data = pipe.stdout.read(size)
            assert len(data) == size and pipe.stdout.read(1) == b'\n'
            sizes.append((size, paths[0], len(paths)))
            if b'\0' not in data:
                for name, pattern in compiled.items():
                    if pattern.search(data):
                        suspicious.append({'kind': name, 'paths': paths})
            # Check one representative per exact staged object. Full source
            # manifests and sealed archives provide per-file provenance.
            path = ROOT / paths[0]
            if path.is_file():
                current = path.read_bytes()
                raw_oid = hashlib.sha1(b'blob '+str(len(current)).encode()+b'\0'+current).hexdigest()
                if raw_oid != oid:
                    byte_changes.append({'path': paths[0], 'line_endings_only': current.replace(b'\r\n', b'\n') == data})
    finally:
        pipe.stdin.close(); pipe.stdout.close(); pipe.wait()
    report = {
        'base_head': git('rev-parse', 'HEAD').decode().strip(),
        'staged_paths': len(entries), 'unique_changed_blobs': len(objects),
        'unique_blob_bytes': sum(x[0] for x in sizes),
        'largest_blobs': sorted(sizes, reverse=True)[:12],
        'suspicious_credential_patterns': suspicious,
        'representative_worktree_byte_differences': byte_changes,
        'limits': 'Pattern scan is a delivery check, not a guarantee of absence of secrets. Exact historical source archives remain the provenance authority.',
    }
    (HERE/'git-delivery-audit.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps({key: report[key] for key in ['staged_paths', 'unique_changed_blobs', 'unique_blob_bytes']}, indent=2))
    print('Credential-pattern matches:', len(suspicious))
    print('Representative byte differences:', len(byte_changes))
    if suspicious or any(size >= 100*1024*1024 for size, _, _ in sizes):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
