from pathlib import Path
import shutil
out=Path(__file__).resolve().parent
root=out.parents[3]
previous=out.parent/'scope-confirmation-20261029-v1'
for name in ['pin.py','run.py']:
    text=(previous/name).read_text(encoding='utf-8').replace('scope-confirmation-', 'research-confirmation-')
    (out/name).write_text(text,encoding='utf-8')
for rel in ['scripts/ui/feature_store.gd','scripts/market/rival_world_checkpoint.gd']:
    target=out/'before'/rel
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(root/'patch-notes'/rel,target)
shutil.copyfile(previous/'source.json',out/'baseline.json')
shutil.copyfile(previous/'source.json',out/'source.json')
(out/'PLAN.md').write_text('''# Research queue confirmation —2026-10-29

Direct user request: match the shared menu design. Replace only the dynamically created admission dialog with the existing animated confirmation component, retain its exact title/body/payment/ownership/supply warnings and OK/Cancel labels. Use a680×480 surface to fit the optional Audio upgrade warning. Preserve all transaction callbacks and Cancel focus. Add only the exact previous runtime source with current-content compatibility so presentation changes do not strand saved active-rival worlds; reject mixed pairs. Preserve dirty work and .codex-godot-temp; no commit/push/export.

Verify actual Store prompts at1152/1280 for normal and upgrade purchases, complete text/control bounds, animation and Cancel/Esc/× passivity; confirm payment once, zero cycles and no early ownership; complete via Research. Capture native rendering. Focused existing Research UI/integration, previous-world restore and Scope prompt regression. Keep late Research lag FAIL/OPEN; no whole-release claim.
''',encoding='utf-8')
print('Prepared source snapshots and isolated run wrapper')
