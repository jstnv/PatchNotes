from pathlib import Path
import hashlib, json

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[3]
startup = json.loads((BASE / 'build-v3/headless-startup.command.json').read_text())
assert startup['exit'] == 0 and not startup['errors'], startup
source = json.loads((BASE / 'source.json').read_text())
assert all(hashlib.sha256((ROOT / 'patch-notes' / k).read_bytes()).hexdigest() == v for k,v in source.items())

# Fresh reads and exact replacements preserve other threads' queue additions.
todo = ROOT / 'docs/codex/TODO.md'
text = todo.read_text(encoding='utf-8-sig')
marker = '## Dispatch and shared constraints\n'
assert marker in text and '2026-10-17 remaining-queue review' not in text
entry = '''
**2026-10-17 remaining-queue review — feasible repair COMPLETE; remaining decision/human gates retained.** [Source-pinned findings, ten captures and disposition](findings/queue-remainder-20261017-v1/README.md) · [session log](logs/2026-10-17-queue-remainder-v1.md). Corrected five corrupted character prefixes in development headings, selected-hand separators, Beta progress and Balanced Production help. Five existing focused suites and two both-size graphical HUD runs pass; all ten captures inspected. The shared export helper now isolates writable temporary storage, rejects Godot errors despite zero exit, and rejects invalid project.binary headers;13 tooling tests pass. Clean export,297-entry package audit and isolated headless startup pass. The only runtime input changed from the accepted final-v4 build is this display-string file; all266 other runtime hashes match. Previous Bank/publisher interaction retains its exact binary boundary. No scoring/save/balance change. This supersedes the development-mojibake follow-up below.

**Current remaining work requiring decisions or external acceptance:**

- **DESIGN:** AI Store/Core planner, detailed policies/entrants/news and population limits; Store era/platform/content rollout; Founder playable career/formation/ownership UI; course effects/amounts and final balance values. Approved foundation integrations are complete; private candidate values remain unapproved.
- **HUMAN / DEVICE:** Bank quote comprehension, soundtrack/SFX mix and device latency, asset approval, clean-machine and human tuning checks. Automated/rendered evidence does not close these.
- **INACCESSIBLE ROUTE:** B7 older-education/newer-Bank elective payoff remains unobserved through the examined legal automatic-service paths; age1 recovery is complete. Do not fabricate a live campaign or silently alter servicing order to reach it.
- **DEFERRED:** mature Fanbase study, Store human-comprehension testing and Steam. No additional approved implementation is left unstarted by this review; detailed dated entries below preserve their original scopes.
'''
text = text.replace(marker, marker + entry, 1)
old = '- Store/era: new cards/prices/fees/platform/multi-parent/three-Core support and complementary calendar gates await detailed authority. Full97-node proposal cannot be recovered from audited summaries alone.'
new = '- Store/era: two-parent and ordered three-Core infrastructure are implemented at structural scope (Handoffs009/010). New cards/prices/fees, platform requirements, complementary calendar gates and rollout await detailed authority. Full97-node proposal cannot be recovered from audited summaries alone.'
assert old in text
todo.write_text(text.replace(old, new, 1), encoding='utf-8')

state = ROOT / 'docs/codex/CURRENT_STATE.md'
text = state.read_text(encoding='utf-8-sig')
marker = '## Current queue execution\n'
assert marker in text
text = text.replace(marker, marker + '\n2026-10-17: **Remaining-queue text repair complete.** [Findings and remaining decisions](findings/queue-remainder-20261017-v1/README.md) · [session log](logs/2026-10-17-queue-remainder-v1.md). Five corrupted development UI prefixes are corrected; scoring, saves and all other runtime inputs are unchanged. Five focused suites, two graphical HUD runs/ten inspected captures, 13 tooling tests and clean297-entry export/package/startup pass. Repaired shared export storage/error/header validation after a reproduced empty project.binary failure. The prior Bank/publisher matrix keeps its prior binary provenance. Remaining work is explicitly DESIGN, human/device acceptance, inaccessible-route evidence or DEFERRED; no approved implementation was left unstarted by this review. No commit or push.\n', 1)
state.write_text(text, encoding='utf-8')

readme = BASE / 'README.md'
text = readme.read_text(encoding='utf-8')
text = text.replace('The initial runner named', 'Isolated exported headless startup: PASS, exit0 with no recorded error markers; [command and profile](build-v3/headless-startup.command.json). No audible or new exported interaction acceptance is claimed.\n\nThe initial runner named', 1)
readme.write_text(text, encoding='utf-8')
print('Updated TODO, CURRENT_STATE and evidence after verified startup/source checks.')
