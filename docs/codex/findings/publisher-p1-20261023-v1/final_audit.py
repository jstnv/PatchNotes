"""Fence final source, packet, native build, ordinary hire and local document links."""
from pathlib import Path
import hashlib,json,re,subprocess
from check import ROOT,OUT,sim

gate=sim.read_json(OUT/'gate3/continuation-result.json')
assert gate.get('combined_pass') is True,gate.get('failure','Final continuation still running')
packet=ROOT/'docs/codex/threads/contracts/handoffs/publisher-p1-foundation-20261023-v1'
sealed=sim.read_json(packet/'handoff-integrity.json')
assert all(sim.sha(packet/name)==digest for name,digest in sealed.items())
baseline=sim.read_json(packet/'base-manifest.json')
current=sim.source_hashes(ROOT/'patch-notes')
changes=[name for name in sorted(set(baseline)|set(current)) if baseline.get(name)!=current.get(name)]
sim.write_json(OUT/'final-source.json',current)
native=sim.read_json(OUT/'export-clean/build-manifest.json')
assert all(sim.sha(ROOT/'patch-notes'/name)==digest for name,digest in native['included'].items())
assert all(sim.sha(ROOT/'patch-notes'/name)==digest for name,digest in native.get('import_settings',{}).items())
for label in ['native-editor','native-editor-current','native-export-old','native-export-current','native-export-founder']:
    assert sim.read_json(OUT/(label+'-exit.json'))['exit']==0,label
    output=(OUT/(label+'.log')).read_text(encoding='utf8',errors='replace')
    assert not any(line.startswith('ERROR:') or 'SCRIPT ERROR' in line for line in output.splitlines()),label
docs=[OUT/'README.md',OUT/'REVIEW.md',ROOT/'docs/codex/logs/2026-10-23-publisher-p1-plan-v1.md',ROOT/'docs/codex/logs/2026-10-23-publisher-p1-adoption-v1.md']
missing=[];links=0
for doc in docs:
    for target in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf8')):
        if '://' in target or target.startswith('#'):continue
        links+=1
        if not (doc.parent/target.split('#')[0]).resolve().exists():missing.append([str(doc),target])
assert not missing,missing
whitespace=subprocess.run(['git','-c','core.whitespace=cr-at-eol','diff','--check','--',*[str(Path('patch-notes')/name) for name in changes],*[str(p.relative_to(ROOT)) for p in docs],'docs/codex/TODO.md','docs/codex/CURRENT_STATE.md','docs/codex/DECISIONS.md','docs/codex/design/publishers-contracts.md'],cwd=ROOT,capture_output=True)
assert whitespace.returncode==0,whitespace.stdout.decode(errors='replace')
sim.write_json(OUT/'final-audit.json',dict(passed=True,source_paths=changes,source_manifest_identity=hashlib.sha256(json.dumps(current,sort_keys=True).encode()).hexdigest(),packet_seals_unchanged=len(sealed),native_runtime_inputs_unchanged=len(native['included']),native_processes_exited_zero=5,maintained_suites=gate['combined_count'],retained_unaffected_suites=gate['retained_count'],new_continuation_suites=len(gate['new_checks']),links=links,missing_links=missing,scoped_whitespace_exit=whitespace.returncode,branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),commit_or_push_performed=False,release_ready=False))
print('FINAL AUDIT PASS',len(changes),'source paths',links,'links')
