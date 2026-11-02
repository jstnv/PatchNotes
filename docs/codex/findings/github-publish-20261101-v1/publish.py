"""Publish an immutable, reviewed snapshot without staging concurrent work."""
from pathlib import Path
import argparse, hashlib, json, os, shutil, subprocess, time

ROOT = Path(__file__).resolve().parents[4]
BASE = Path(__file__).resolve().parent
SNAP = BASE / 'verified-source'
EXPECTED = '49d769235474a880a73d996499cefa72beec63e5'

def git(*args, data=None, index=None):
    env = os.environ.copy()
    if index is not None:
        env['GIT_INDEX_FILE'] = str(index)
    return subprocess.check_output(['git', '-c', 'core.longpaths=true', *args], cwd=ROOT, env=env, input=data)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()

def tree(ref):
    result = {}
    for row in git('ls-tree', '-rz', ref).split(b'\0'):
        if row:
            header, path = row.split(b'\t', 1)
            mode, kind, oid = header.decode().split()
            if kind == 'blob':
                result[path.decode()] = (mode, oid)
    return result

def save(name, obj):
    (BASE / name).write_text(json.dumps(obj, indent=2) + '\n', encoding='utf-8')

def records(items):
    return b''.join((mode + ' ' + oid + '\t' + path).encode() + b'\0'
                    for path, (mode, oid) in items.items())

def prepare():
    assert git('rev-parse', 'HEAD').decode().strip() == EXPECTED
    prior = tree(EXPECTED)
    changes = []
    for parent, dirs, files in os.walk(SNAP):
        dirs[:] = [d for d in dirs if d not in ['.godot', '__pycache__', 'profile',
                                              'profiles', 'import-profile', 'APPDATA', 'LOCALAPPDATA']]
        for name in sorted(files):
            p = Path(parent) / name
            rel = p.relative_to(SNAP).as_posix()
            assert not any(c in rel for c in '\n\r\t\0')
            assert not any(q in ['.codex-godot-temp', '.godot', 'APPDATA', 'LOCALAPPDATA',
                                'profile', 'profiles', 'import-profile'] for q in Path(rel).parts)
            data = p.read_bytes()
            oid = blob(data)
            mode = prior.get(rel, ('100644', ''))[0]
            if prior.get(rel) != (mode, oid):
                assert len(data) < 50 * 1024 * 1024, rel
                changes.append({'path': rel, 'sha256': sha(data), 'oid': oid,
                                'mode': mode, 'size': len(data)})
    changes.sort(key=lambda x: x['path'])
    # Do not include changes outside the completed source and its reviewed records.
    assert not any('proprietary_engine_state.gd' in x['path'] or
                   'bass_presence_v05' in x['path'] for x in changes)
    index = BASE / 'publish-index'
    git('read-tree', EXPECTED, index=index)
    input_paths = ''.join((SNAP / x['path']).as_posix() + '\n' for x in changes)
    oids = git('hash-object', '-w', '--no-filters', '--stdin-paths',
               data=input_paths.encode()).decode().splitlines()
    assert oids == [x['oid'] for x in changes]
    git('update-index', '-z', '--index-info',
        data=records({x['path']: (x['mode'], x['oid']) for x in changes}), index=index)
    new_tree = git('write-tree', index=index).decode().strip()
    plan = {'parent': EXPECTED, 'tree': new_tree, 'changes': changes,
            'count': len(changes), 'uncompressed_bytes': sum(x['size'] for x in changes)}
    save('commit-plan.json', plan)
    authored = [x['path'] for x in changes
                if Path(x['path']).suffix in ['.gd', '.py', '.godot', '.md']
                and not x['path'].startswith('docs/codex/findings/')]
    # Raw test logs keep their original hashes, including printed spaces.
    git('-c', 'core.whitespace=cr-at-eol', 'diff', '--cached', '--check',
        '--', *authored, index=index)
    print(json.dumps({k: v for k, v in plan.items() if k != 'changes'}))

def commit():
    plan = json.loads((BASE / 'commit-plan.json').read_text())
    tests = json.loads((BASE / 'prepush/results.json').read_text())
    public = json.loads((BASE / 'prepush-public/results.json').read_text())[0]
    tests = [public if x['name'] == 'verify_public_action_engine' else x for x in tests]
    assert len(tests) == 9 and all(x['ok'] and x['exit'] == 0 for x in tests)
    for row in tests:
        folder = 'prepush-public' if row['name'] == 'verify_public_action_engine' else 'prepush'
        lines = (BASE / folder / row['name'] / 'godot.log').read_text(errors='replace').splitlines()
        assert not any(s.startswith(('ERROR:', 'SCRIPT ERROR:', 'FAIL:')) for s in lines)
    for x in plan['changes']:
        assert sha((SNAP / x['path']).read_bytes()) == x['sha256'], x['path']
    assert git('rev-parse', 'HEAD').decode().strip() == EXPECTED
    assert git('symbolic-ref', 'HEAD').decode().strip() == 'refs/heads/main'
    message = BASE / 'commit-message.txt'
    signing = subprocess.run(['git', 'config', '--bool', '--get', 'commit.gpgsign'],
                             cwd=ROOT, capture_output=True, text=True).stdout.strip()
    args = ['commit-tree', plan['tree'], '-p', EXPECTED, '-F', str(message)]
    if signing == 'true':
        args.append('-S')
    new_commit = git(*args).decode().strip()
    published = tree(new_commit)
    manifest = json.loads((ROOT / 'docs/codex/findings/checksum-combined-20261101-v1/final-source-manifest.json').read_text())
    for rel, digest in manifest.items():
        data = (SNAP / 'patch-notes' / rel).read_bytes()
        assert sha(data) == digest
        assert published['patch-notes/' + rel][1] == blob(data)
    # Update only unmodified baseline entries in the shared index. Preserve any
    # separately staged work and all working files. Hold Git's normal index lock
    # while comparing entries and advancing HEAD with an expected-old lease.
    git_dir = Path(git('rev-parse', '--absolute-git-dir').decode().strip())
    lock = git_dir / 'index.lock'
    deadline = time.monotonic() + 20
    while True:
        try:
            with lock.open('xb'):
                pass
            break
        except FileExistsError:
            if time.monotonic() >= deadline:
                raise RuntimeError('Another Git writer still owns index.lock')
            time.sleep(.1)
    preserved = []
    try:
        current = {}
        for row in git('ls-files', '--stage', '-z').split(b'\0'):
            if row:
                meta, path = row.split(b'\t', 1)
                mode, oid, stage = meta.decode().split()
                assert stage == '0', 'Unmerged index entry'
                current[path.decode()] = (mode, oid)
        old = tree(EXPECTED)
        replacements = {}
        for x in plan['changes']:
            path = x['path']
            if current.get(path) == old.get(path):
                replacements[path] = published[path]
            else:
                preserved.append(path)
        merged = BASE / 'merged-index'
        shutil.copyfile(git_dir / 'index', merged)
        git('update-index', '-z', '--index-info', data=records(replacements), index=merged)
        with lock.open('wb') as f:
            f.write(merged.read_bytes())
            f.flush()
            os.fsync(f.fileno())
        git('update-ref', '-m', 'Publish verified checksum and combined gameplay fixes',
            'refs/heads/main', new_commit, EXPECTED)
        os.replace(lock, git_dir / 'index')
    except BaseException:
        if lock.exists():
            lock.unlink()
        raise
    save('commit-result.json', {'commit': new_commit, 'parent': EXPECTED,
                              'tree': plan['tree'], 'preserved_staged_paths': preserved,
                              'verified_source_files': len(manifest), 'prepush_names': 9})
    print(json.dumps({'commit': new_commit, 'preserved_staged_paths': preserved}))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['prepare', 'commit'])
    command = parser.parse_args().mode
    prepare() if command == 'prepare' else commit()
