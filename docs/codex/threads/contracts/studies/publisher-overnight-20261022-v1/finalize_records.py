"""Record executed CLI invocations and check the new thread-owned packet."""
import hashlib,json,pathlib,re,subprocess
H=pathlib.Path(__file__).resolve().parent;T=H.parents[1];ROOT=H.parents[5]
commands=[
 '& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/prepare.py',
 '& $pnPython tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/publisher-support-1112-pair-20261022-v1 --case sports-1112-support --output docs/codex/threads/contracts/sims/publisher-overnight-baseline-replay-20261022-v1 --timeout 360 --godot $pnGodot']
for n in ['weak-pairs','renewal','recovery','renewal-reduced','revival']:
    commands.append(f'& $pnPython tools/simulate.py run --variant $pnVariant --config docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/{n}.json --output docs/codex/threads/contracts/sims/publisher-overnight-{n}-20261022-v1 --timeout 360 --godot $pnGodot')
for b,c,o in [('renewal-reduced','second-support-minimal','renewal-reduced-replay'),('weak-pairs','weak2-support','weak-replay'),('revival','post-cutoff-revival','revival-replay')]:
    commands.append(f'& $pnPython tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/publisher-overnight-{b}-20261022-v1 --case {c} --output docs/codex/threads/contracts/sims/publisher-overnight-{o}-20261022-v1 --timeout 360 --godot $pnGodot')
commands.extend([
 '& $pnPython tools/simulate.py run --variant $pnVariant --config docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/recovery-renewal.json --output docs/codex/threads/contracts/sims/publisher-overnight-recovery-renewal-20261022-v1 --timeout 360 --godot $pnGodot',
 '& $pnPython tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/publisher-overnight-recovery-20261022-v1 --case miss-recovery-commission --output docs/codex/threads/contracts/sims/publisher-overnight-recovery-replay-20261022-v1 --timeout 360 --godot $pnGodot'])
prefix="""# Exact executed study commands

2026-10-22. Run from the repository root. Aliases below stand for the exact executables/variant passed on each command. All six run and five replay invocations returned0; three run cases nevertheless failed the required ending-checkpoint acceptance. The original output folders must be retained; reproductions require fresh output paths. This record is not a script to rerun over existing evidence.

```powershell
$pnPython = 'C:\\Users\\64jus\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe'
$pnGodot = 'C:\\Users\\64jus\\Downloads\\Godot_v4.7.1-stable_win64.exe\\Godot_v4.7.1-stable_win64_console.exe'
$pnVariant = 'docs/codex/threads/contracts/simulators/publisher-progression-support-market-v1'
"""
suffix="""
```

Input generation and audits also executed with the same Python:

```powershell
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/followup_prepare.py
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/prepare_recovery_renewal.py
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/renewal_model.py renewal-model.json
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/renewal_model.py renewal-model-replay.json
& $pnPython docs/codex/threads/contracts/studies/publisher-overnight-20261022-v1/audit.py audit-v1.json
```

Inputs were prepared before their dependent runs. Independent pairs of processes were allowed concurrently; no shared mutable project/profile was used. Each run bundle retains original input hashes, exact Godot command JSON, exit/timeout logs, source manifests, runner snapshot, and isolated profile. No seed, budget or output was silently replaced. The minimal failure reduction and campaign revival were declared in PLAN.md before execution.
"""
p=H/'COMMANDS.md'
if p.exists():raise RuntimeError('Refusing command record overwrite')
p.write_text(prefix+'\n'.join(commands)+suffix,encoding='utf-8')

# Narrow live-read replacements in this thread's handoff only; preserve all other bytes.
p=T/'HANDOFF.md';original=p.read_bytes();data=original
replacements={
 'Review/Month3 units milestone, capacity-step issuance and future Investment gain.':'Review/Month3 units milestone, proposed v4 qualifying-result renewal and future Investment gain.',
 'Preserve the proposed capacity-step repeat rule by validating chronological multiple support deals and their rights/events in checkpoints; a second quote must never lead to an unsavable Studio. Test a legal sixth-cycle miss, an uncapped age-24 cutoff, a second deal and cold restore.':'Review v4 qualifying-result renewal and validate chronological multiple support deals and their rights/events in checkpoints; a second quote must never lead to an unsavable Studio. The overnight finding supplies two legal misses, an uncapped positive-sales post-expiry witness and a reproducible second-deal save failure. Repair and retest that failure, exact cutoff-boundary timing and native cold restore.'}
for old,new in replacements.items():
    before=old.encode();after=new.encode()
    if data.count(before)!=1:raise RuntimeError('Handoff changed; re-read before replacing')
    data=data.replace(before,after,1)
if p.read_bytes()!=original:raise RuntimeError('Concurrent handoff edit')
p.write_bytes(data)

files=[T/n for n in ['PUBLISHER-OVERNIGHT-FINDINGS-2026-10-22-v1.md','HANDOFF-PUBLISHER-OVERNIGHT-2026-10-22-v1.md','PUBLISHER-RENEWAL-AND-FAILURE-PROPOSAL-2026-10-22-v4.md','PUBLISHER-OFFER-AND-FINANCE-SPEC-2026-10-22-v1.md','SESSION-LOG-2026-10-22-publisher-overnight-v1.md']]+[H/'PLAN.md',H/'COMMANDS.md']
issues=[];links=0
for p in files:
    text=p.read_text(encoding='utf-8')
    for i,line in enumerate(text.splitlines(),1):
        if line.rstrip()!=line:issues.append(f'{p.name}:{i}: trailing whitespace')
    for link in re.findall(r'\]\(([^)]+)\)',text):
        if '://' in link or link.startswith('#'):continue
        links+=1
        if not (p.parent/link.split('#')[0]).exists():issues.append(f'{p.name}: missing {link}')
model_a=(H/'renewal-model.json').read_bytes();model_b=(H/'renewal-model-replay.json').read_bytes()
if model_a!=model_b:issues.append('model outputs differ')
replays=[]
for n in ['baseline-replay','weak-replay','renewal-reduced-replay','revival-replay','recovery-replay']:
    rr=json.loads((T/f'sims/publisher-overnight-{n}-20261022-v1/replay-report.json').read_text())
    replays.append({'name':n,'ok':rr['ok'],'commands':len(rr['steps']),'telemetry':rr.get('telemetry_samples')})
    if not rr['ok'] or not rr.get('telemetry_verified'):issues.append(f'replay {n}')
report={'files_checked':len(files),'links_checked':links,'issues':issues,'model_outputs_identical':model_a==model_b,
        'model_sha256':hashlib.sha256(model_a).hexdigest(),'replays':replays,'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()}
(H/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))
if issues:raise SystemExit(1)
