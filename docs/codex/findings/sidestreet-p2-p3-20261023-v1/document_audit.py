from pathlib import Path
import importlib.util,json,re,subprocess
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def main():
    docs=[HERE/'README.md',HERE/'REVIEW.md',ROOT/'docs/codex/logs/2026-10-24-sidestreet-p2-p3-adoption-v1.md',ROOT/'docs/codex/logs/2026-10-23-sidestreet-p2-p3-plan-v1.md']
    missing=[];links=0
    for path in docs:
        text=path.read_text(encoding='utf8')
        assert not any(line.rstrip()!=line for line in text.splitlines()),path
        for target in re.findall(r'\]\(([^)]+)\)',text):
            if '://' in target or target.startswith('#'):continue
            links+=1
            if not (path.parent/target.split('#')[0]).resolve().exists():missing.append([str(path),target])
    assert not missing,missing
    shared=['docs/codex/TODO.md','docs/codex/CURRENT_STATE.md','docs/codex/DECISIONS.md','docs/codex/design/publishers-contracts.md','docs/codex/threads/contracts/README.md']
    whitespace=subprocess.run(['git','-c','core.whitespace=cr-at-eol','diff','--check','--',*shared,*[str(p.relative_to(ROOT)) for p in docs]],cwd=ROOT,capture_output=True)
    assert whitespace.returncode==0,whitespace.stdout.decode(errors='replace')
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    assert sim.source_hashes(ROOT/'patch-notes')==json.loads((HERE/'final-source.json').read_text(encoding='utf8')),'Canonical source changed after verification'
    todo=(ROOT/'docs/codex/TODO.md').read_text(encoding='utf8')
    assert '2026-10-24 SideStreet P2/P3 — IMPLEMENTED locally' in todo and 'SideStreet P2/P3 — QUEUED' not in todo
    assert json.loads((HERE/'final-audit.json').read_text(encoding='utf8'))['release_ready'] is False
    result={'pass':True,'checked_local_links':links,'missing_links':missing,'scoped_whitespace_exit':whitespace.returncode,'canonical_source_unchanged':True,'todo_blocked_exe_preserved':True,'commit_or_push_performed':False}
    sim.write_json(HERE/'document-audit.json',result);print(json.dumps(result))
if __name__=='__main__':main()
