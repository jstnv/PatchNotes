from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
todo=ROOT/'docs/codex/TODO.md'
# Read immediately before one scoped replacement so concurrent handoffs survive.
s=todo.read_text(encoding='utf-8')
paragraphs=s.split('\n\n')
matches=[p for p in paragraphs if p.startswith('**Crown grade feedback and zero-award reminder — QUEUED')]
assert len(matches)==1
(OUT/'TODO.crown-before.md').write_text(matches[0]+'\n',encoding='utf-8')
new='**Crown grade feedback and zero-award reminder — IMPLEMENTED and verified privately,2026-10-26; canonical catalog adoption remains gated.** Approved GF2–GF6 feedback is staged in a current-source isolated simulator: exact provisional/final grade and cap details, final-hand current-card zero warning, and validated consecutive-zero reminder. Rewards unchanged.30 model checks,125 editor/125 compiled-pack transaction checks,78 editor/78 exported-content native UI checks,8+8 cold/replay assertions, maintained Search/relationship/Contract/world checks and an unfunded227-command/three-release/three-Brief campaign pass. [Source, exact coverage and remaining adoption gates](logs/2026-10-26-crown-feedback-v1.md) · [sealed private packet](threads/contracts/handoffs/crown-feedback-20261026-v1/HANDOFF.md) · [approved v4 handoff](threads/contracts/CROWN-PREVIEW-HANDOFF-2026-10-25-v4.md). No canonical Crown exposure, approved old-save migration, populated-rival Crown campaign, human comprehension or player EXE/ZIP acceptance is implied. Employee Research and the proposed Crown paid-work package remain separate design work.'
s=s.replace(matches[0],new)
needle='**Insider-hold economy — OPEN observation, not approved compensation.**'
old=next(p for p in s.split('\n\n') if p.startswith(needle))
s=s.replace(old,old+' A separately verified legal Action/4417 route now reaches three releases at cycle128 with $19,014.73 and no arrears through18 paid SideStreet Cash searches and later Research; no funding was injected. [Exact policy and limits](logs/2026-10-26-crown-feedback-v1.md). This alternate route does not close the shorter fixed-policy finding or final balance.')
old=next(p for p in s.splitlines() if p.startswith('- Employees/courses:'))
s=s.replace(old,'- Employees/courses: after-Game-2 browsing/hiring is reopened locally by the explicit2026-10-26 user direction; the menu-opening fix is complete above. Explicit trial activation enables existing Production/QA courses and prospective$1,000 base payroll; historical ordinary saves retain their wages until activation. The failed dual-hire economic study remains evidence, not a current button hold. QA25% replay-search remains ACTIVE/TRIAL. Employee Research accounting/duties/cadence and other specialties remain design work, not queued implementation.')
todo.write_text(s,encoding='utf-8',newline='\n')
for relative,entry in [
 ('docs/codex/CURRENT_STATE.md','**2026-10-26 Crown Brief feedback — IMPLEMENTED and verified privately.** A new simulator based on current canonical source includes approved provisional/final grade Details, final-hand zero-choice warning and quiet validated zero-streak advice.30 model checks,125 editor/125 compiled-pack transaction checks,78+78 native UI checks,8+8 cold/replay assertions and a fresh unfunded227-command/three-release/three-Brief campaign pass. Canonical gameplay and the player EXE/ZIP are unchanged; Crown catalog adoption/migration and human/device acceptance remain gated. [Source, sealed packet and limits](logs/2026-10-26-crown-feedback-v1.md).'),
 ('docs/codex/design/publishers-contracts.md','**2026-10-26 Crown feedback — approved private implementation complete.** Exact selected-hand provisional/final grade and cap credit, a final-hand-only current-card zero warning, and a quiet reminder after two consecutive zero-requested Brief awards are implemented and verified in an isolated current-source candidate. Positive requested/cap-zero credit resets the derived count; incomplete history is unavailable; R100 suppresses proactive advice. No durable streak field or reward change. Normal catalog exposure and named canonical migration remain separate adoption gates. [Implementation, tests and source](../logs/2026-10-26-crown-feedback-v1.md).')]:
 p=ROOT/relative;text=p.read_text(encoding='utf-8');head,rest=text.split('\n',1)
 p.write_text(head+'\n\n'+entry+'\n'+rest,encoding='utf-8',newline='\n')
plan=ROOT/'docs/codex/logs/2026-10-26-crown-feedback-plan-v1.md'
text=plan.read_text().replace('- [ ]','- [x]')
text+='\nOutcome: completed at the specified private automated scope. See the dated closeout for exact source, retained failures and canonical/human acceptance gates. No canonical gameplay adoption or commit/push.\n'
plan.write_text(text,encoding='utf-8',newline='\n')
print('PASS: minimal queue/design/state reconciliation; concurrent design handoffs preserved')
