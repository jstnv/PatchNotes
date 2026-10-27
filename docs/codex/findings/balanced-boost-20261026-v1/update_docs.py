from pathlib import Path
root=Path(__file__).resolve().parents[4]
def update(name, change):
    p=root/'docs/codex'/name
    data=p.read_bytes(); nl='\r\n' if b'\r\n' in data else '\n'
    s=data.decode().replace('\r\n','\n')
    p.write_bytes(change(s).replace('\n',nl).encode())

entry='**2026-10-26 Balanced Production bonus — IMPLEMENTED locally.** Multiply raw hand Core by1.25, floor the total once, then share whole points across Graphics/Sound/Technology/Design (21→26→7/7/6/6). The inclusive±15% hand trigger, Feature requirement, Specialization precedence, printed Scope/pressure and music grid remain.1,295 arithmetic/AI checks, Design/Alpha phase and command suites,6 exact live/headless comparisons,80 characterization cases,27 model/115 native tutorial checks,3,503 sync checks and10 predecessor restore checks pass. [Source and limits](logs/2026-10-26-balanced-boost-v1.md). Existing player EXE/ZIP unchanged.\n\n'
for name in ['CURRENT_STATE.md','TODO.md']:
    # Read immediately before each minimal prepend to preserve incoming handoffs.
    update(name,lambda s:s.replace('\n\n','\n\n'+entry,1))

decision='## 2026-10-26 — Balanced Production boosts before sharing\n\nDirect user instruction, IMPLEMENTED locally: award1.25 times this hand’s raw primary-plus-secondary Core total, then share across the four categories. Preserve the prior inclusive±15% trigger, Feature gate and Specialization precedence. Whole-point implementation: floor the boosted total once, then fixed Graphics/Sound/Technology/Design remainder order (21→26→7/7/6/6). Supersedes the2026-10-10 reward that conserved the original total; Scope, printed Bug Pressure, price/time/exhaustion and historical releases remain unchanged. Shared live/headless/rival authority; old replay identities and private variants stay source-fenced. [Verification and limits](logs/2026-10-26-balanced-boost-v1.md).\n\n'
update('DECISIONS.md',lambda s:s.replace('\n\n','\n\n'+decision,1))

design='## Balanced Production bonus — 2026-10-26\n\n**IMPLEMENTED locally by direct user request:** take this hand’s raw primary-plus-secondary Core total, multiply by1.25, floor the total once, then split whole points evenly across four categories. Spare points follow Graphics, Sound, Technology, Design:21→26→7/7/6/6;8→10→3/3/2/2. The qualifying hand still needs positive output, each category within inclusive±15% of the raw four-category average, and at least one Feature. Specialization takes precedence and does not stack. Scope, printed Bug Pressure, costs, cycles and exhaustion stay unchanged.\n\nThis reward supersedes the original-total conservation rule below. Printed gains still appear first; the boosted split applies once after the popup on the same music grid, without another bounce. Live Design/Alpha, headless commands, rival evaluation and tutorial share the formula. Stored history is retained; future hands use the new reward. [Source, rounding, checks and limits](../logs/2026-10-26-balanced-boost-v1.md).\n\n'
update('design/core-and-studio.md',lambda s:s.replace('## Balanced Production redistribution — 2026-10-10',design+'## Balanced Production redistribution — 2026-10-10 (reward SUPERSEDED2026-10-26)'))
