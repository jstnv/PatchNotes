from pathlib import Path
root=Path(__file__).resolve().parents[4]
for name in ['TODO.md','CURRENT_STATE.md']:
    path=root/'docs/codex'/name;text=path.read_text(encoding='utf-8')
    for old,new in [
      ('**2026-10-29 Production Specialist courses — QUEUED for coordinated candidate implementation; NOT IMPLEMENTED.**','**2026-10-29 Production Specialist courses — IMPLEMENTED locally as an ACTIVE/TRIAL candidate; final refreshed acceptance IN PROGRESS.**'),
      ('**2026-10-28 Project Manager priority-range trial — QUEUED for coordinated implementation review; NOT IMPLEMENTED.**','**2026-10-28 Project Manager priority-range trial — IMPLEMENTED locally as an ACTIVE/TRIAL candidate; final refreshed acceptance IN PROGRESS.**'),
    ]:text=text.replace(old,new,1)
    note='**2026-10-29 employee courses / F8 Developer Tools — local implementation, final verification IN PROGRESS.** Two Production courses, four Project Manager courses, earned bounds, exact tuition/prospective payroll and legacy migration are wired. F8 opens session-only unlimited money/current-Feature tools after saving the normal Studio; debug progress never writes Continue. Focused headless/native checks have passed on recorded intermediate sources; the current-source final campaign/replay batch is still running. Matched unfunded affordability failures remain OPEN; no final-balance, no-lag, export, commit or push claim. [Design](design/debug-mode.md) · [execution ledger](findings/employee-courses-20261029-v1/LEDGER.md) · [fresh review](findings/employee-courses-20261029-v1/REVIEW.md). Earlier NOT IMPLEMENTED entries below are historical.\n\n'
    first,rest=text.split('\n\n',1);text=first+'\n\n'+note+rest
    path.write_text(text,encoding='utf-8')
