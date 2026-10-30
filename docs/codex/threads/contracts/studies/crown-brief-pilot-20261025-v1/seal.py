from run import *
args=[PY,'tools/simulator_variant.py','handoff','--variant',str(VAR),'--design-record',str(THREAD/'CROWN-BRIEFS-DESIGN-2026-10-25-v1.md'),'--summary','DESIGN review only: bounded Crown Brief accessibility/pacing prototype; existing rewards unchanged; no canonical adoption approval. See Crown Brief pilot finding/handoff for unverified migration/lifecycle/UI gates.','--acceptance','Do not adopt until explicit Crown numeric/activation approval and named prospective migration, active-rival, forged-history, atomic rejection, UI/export acceptance are complete.','--acceptance','Preserve existing publisher rewards; reproduce source-matched legal full/partial/zero Briefs, once-only standing, finite cards, release pacing and Studio-only state/RNG continuation.','--output',str(THREAD/'handoffs/crown-brief-pilot-20261025-v1')]
args[-1]=str(THREAD/'handoffs/crown-brief-pilot-20261025-v3')
for name in ['branches-4521','branches-4522','witness','cold']:
    args+=['--evidence',str(RAW/name)]
execute('seal-design-review-v3',args)
