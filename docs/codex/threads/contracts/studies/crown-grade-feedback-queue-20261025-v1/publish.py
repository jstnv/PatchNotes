"""Publish only the approved feedback queue/status; retain byte-level preimages."""
from pathlib import Path
import hashlib
import json
import re
import subprocess

HERE = Path(__file__).resolve().parent
THREAD = HERE.parent.parent
ROOT = THREAD.parents[3]
TODO = ROOT / 'docs/codex/TODO.md'
sha = lambda data: hashlib.sha256(data).hexdigest()

assert not (HERE / 'receipt.json').exists(), 'Publication already recorded; do not rerun.'
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
branch = subprocess.check_output(['git', 'branch', '--show-current'], cwd=ROOT, text=True).strip()
assert head == '0132c4dab398a2a94dbeae3caa68a36505fbfa4f' and branch == 'main'

old = TODO.read_bytes()  # Re-read shared execution authority immediately before minimal replacement.
lines = [s for s in old.splitlines(keepends=True) if s.startswith(b'**Crown paid-Search Brief')]
assert len(lines) == 1
old_line = lines[0]
text = old_line.decode('utf-8')
old_header = '**Crown paid-Search Brief — DESIGN review needed; approved pilot terms and private evidence,2026-10-25.**'
new_header = '**Crown grade feedback and zero-award reminder — QUEUED for PN Implementation; user APPROVED,2026-10-25. Crown catalog exposure retains its existing gates.**'
assert text.startswith(old_header)
text = text.replace(old_header, new_header, 1)
start = text.index(' Latest [grade-feedback design and fixtures]')
ending = '\r\n' if old_line.endswith(b'\r\n') else '\n'
text = text[:start] + ' [User approval](threads/contracts/CROWN-GRADE-FEEDBACK-APPROVAL-2026-10-25-v1.md) and [v4 implementation handoff GF2–GF6](threads/contracts/CROWN-PREVIEW-HANDOFF-2026-10-25-v4.md) queue exact provisional/final grade feedback, the final-hand current-card zero warning, and a quiet reminder after two consecutive zero-earned Crown Briefs with cap/history safeguards. Rewards unchanged. [Matching offline evidence](threads/contracts/CROWN-GRADE-FEEDBACK-FINDINGS-2026-10-25-v1.md):36 recorded projections/18 results,1,260 current-card evaluations,48 constructed cases and603 arithmetic checks. Presentation and threshold2 are approved; current-source reconciliation, native query purity, live ledger/Studio restore and UI/export acceptance remain implementation work. Canonical Crown catalog exposure retains the existing CSB authority and adoption gates; broader progression/final balance review remains separate.' + ending
new_line = text.encode('utf-8')
new = old.replace(old_line, new_line, 1)
(HERE / 'TODO.before.md').write_bytes(old)
assert TODO.read_bytes() == old, 'Concurrent TODO edit; retry from fresh source.'
TODO.write_bytes(new)
assert TODO.read_bytes().replace(new_line, old_line, 1) == old
receipt = {'branch': branch, 'head': head, 'todo_before_sha256': sha(old), 'todo_after_sha256': sha(new), 'unrelated_todo_bytes_preserved': True, 'indexes': {}}

summary = '**2026-10-25 Crown grade feedback — APPROVED and QUEUED for PN Implementation.** [User approval](CROWN-GRADE-FEEDBACK-APPROVAL-2026-10-25-v1.md) approves selected-card grade feedback, the final-hand current-card zero warning and the quiet consecutive-two zero-earned reminder, including cap/history safeguards. [Implementation handoff v4](CROWN-PREVIEW-HANDOFF-2026-10-25-v4.md) supersedes the presentation-proposed status and DESIGN-only queue instruction below and in v3. Rewards unchanged. Native integration, ledger/restore, purity and UI/export acceptance remain work for PN Implementation; broader Crown catalog exposure retains its existing gates. Historical findings below remain evidence, not current approval status.'
for name in ['README.md', 'HANDOFF.md']:
    path = THREAD / name
    before = path.read_bytes()
    delimiter = b'\r\n\r\n' if b'\r\n' in before else b'\n\n'
    offset = before.index(delimiter) + len(delimiter)
    insert = summary.encode('utf-8') + delimiter
    after = before[:offset] + insert + before[offset:]
    (HERE / (name + '.before')).write_bytes(before)
    assert path.read_bytes() == before, 'Concurrent thread index edit.'
    path.write_bytes(after)
    assert path.read_bytes().replace(insert, b'', 1) == before
    receipt['indexes'][name] = {'before_sha256': sha(before), 'after_sha256': sha(after), 'prior_bytes_preserved': True}

checked = 0
for name in ['CROWN-GRADE-FEEDBACK-APPROVAL-2026-10-25-v1.md', 'CROWN-PREVIEW-HANDOFF-2026-10-25-v4.md']:
    path = THREAD / name
    for link in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
        assert (path.parent / link).resolve().exists(), link
        checked += 1
for link in re.findall(r'\]\(([^)]+)\)', new_line.decode('utf-8')):
    assert (TODO.parent / link).resolve().exists(), link
    checked += 1
receipt.update({'local_links_checked': checked, 'status': 'PASS', 'gameplay_tests': 'NOT RUN: documentation-only queue update', 'simulation_runs': 'NOT RUN: existing matching evidence retained'})
(HERE / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
print(json.dumps(receipt, indent=2))
