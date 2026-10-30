from pathlib import Path
import difflib, hashlib, json, subprocess

root = Path(__file__).resolve().parents[4]
game = root / 'docs/codex/findings/gameplay-adoption-20261028-v1'
scope = Path(__file__).resolve().parent
runtime = root / 'patch-notes'
identity = '56b304839cd4653d27baa368bcadb7f6cc83c8afc7ed4d813ef5d1c94766b60d'

def write(path, text):
    path.write_bytes((text.rstrip()+'\n').replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))

def prepend(path, text):
    content = path.read_text(encoding='utf-8')
    first, rest = content.split('\n',1)
    write(path, first+'\n\n'+text+'\n'+rest.lstrip('\n'))

owned = []
baseline = json.loads((game/'baseline.json').read_text(encoding='utf-8'))
source = json.loads((game/'source.json').read_text(encoding='utf-8'))
for name, sha in source['runtime_files'].items():
    if baseline['runtime_files'].get(name) == sha:
        continue
    rel = name.removeprefix('res://')
    old = game/'before'/rel
    new = runtime/rel
    assert old.exists(), str(old)
    assert hashlib.sha256(new.read_bytes()).hexdigest() == sha
    owned.append({'path':name,'before':baseline['runtime_files'].get(name),'after':sha})
    target = game/'owned-diffs'/Path(rel+'.diff')
    target.parent.mkdir(parents=True,exist_ok=True)
    write(target, ''.join(difflib.unified_diff(old.read_text(encoding='utf-8').splitlines(True),new.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel)))
assert len(owned) == 7, owned
write(game/'owned-source.json',json.dumps({'baseline':baseline['runtime_identity'],'current':identity,'files':owned},indent=2))

def receipts(folder, names):
    result = []
    for name in names:
        p = folder/(name+'-run.json')
        data = json.loads(p.read_text(encoding='utf-8'))
        assert data['exit'] == 0 and not data['errors'], name
        assert data['runtime_identity'] == identity and data['runtime_source_unchanged'], name
        result.append({'receipt':p.relative_to(root).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'command':data['command'],'exit':data['exit'],'elapsed_seconds':data['elapsed_seconds'],'tail':data['tail']})
    return result

game_receipts = receipts(game,['mechanics-final','actual-play-final','fresh-final','final-grid','final-cold','three-ui-final','refresh-final','retained-audio-final','research-final','store-final','old-gameplay'])
scope_receipts = receipts(scope,['theme-green','theme-native','alpha-finalization','alpha-arrears','source-parity-private'])
branch = subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip()
head = subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
scene = runtime/'scenes/phases/alpha_phase.tscn'
scene_sha = hashlib.sha256(scene.read_bytes()).hexdigest()
assert scene_sha == '0d3c87297f43af40a7fdb32c1fa5cdabcca4158f69b45a1d515fe22acbb68d41'
write(scope/'owned-scene.diff',''.join(difflib.unified_diff((scope/'alpha_phase.tscn.before').read_text(encoding='utf-8').splitlines(True),scene.read_text(encoding='utf-8').splitlines(True),fromfile='before/alpha_phase.tscn',tofile='after/alpha_phase.tscn')))
common = {'date':'2026-10-29','branch':branch,'HEAD':head,'runtime_identity':identity,'worktree':'Inherited dirty tree preserved; no commit/push/export. .codex-godot-temp preserved.','warnings':'Existing ObjectDB fixture/artwork warnings retained; no leak/artwork repair claim.','limits':'Focused acceptance only. Late Research performance FAIL/OPEN; no release or universal parity claim.'}
write(game/'verification.json',json.dumps({**common,'passes':game_receipts,'integration':scope_receipts[-1],'retained_failures':['graph-red','three-card-red2','three-card-red launch failure (missing console executable)'],'pending':'Inventory System -> Score System remains unanswered; Score System remains a root.'},indent=2))
write(scope/'verification.json',json.dumps({**common,'scene_sha256':scene_sha,'passes':scope_receipts,'retained_failures':['theme-red: 50 checks, 12 expected styling failures','source-parity and source-parity-diagnostic: initial writer_busy before test isolation repair'],'test_isolation':'Debug campaign fixture now uses existing TestStore with PN_CHECKPOINT_TEST_PORT when supplied; production writer port/validation unchanged.','native_captures_inspected':['theme-native.json-1152.png','theme-native.json-1280.png']},indent=2))
write(game/'REVIEW.md','''# Gameplay restoration review —2026-10-29

Read-only reviewer `/root/gameplay_restoration_review` compared the seven owned runtime changes against the recorded baseline. No specific actionable defect found. Approved definitions, ordered three-parent acquisition, shared familiarity cap, grandfathered queues, exact source/content compatibility pairs, frozen supply and the pending Score-root choice were preserved. The900px capture showed all links and selected card visible without overlap. No Godot runs were performed by the reviewer; executed main-task checks are recorded in verification.json. No new per-cycle hook/cache was introduced. Late Research latency remains OPEN.
''')

write(root/'docs/codex/design/gameplay-feature-restoration-2026-10-29.md','''# Gameplay restoration —2026-10-29

IMPLEMENTED locally; new numeric rows ACTIVE/TRIAL after the user's explicit approval. This adopts only the selected Gameplay subset of Handoff023. The earlier Gameplay rows were unchanged by the Audio/Technology passes; the missing additions were still pending adoption.

| Card | Printed Core, in order | Scope | Base price | Acquisition parents |
|---|---|---|---|---|
| Timer System | Technology2, Design1 |1|$950|Root|
| Inventory System | Technology3, Design2 |2|$1,700|Root|
| Categorized Scores | Design7, Technology2 |3|$2,400|Timer System AND Score System AND Lives System|

All three are finite, non-upgrade Design Features, with $0 direct play fee and no added year/release gate. Existing Alpha Power-Ups is now a child of Categorized Scores; its effects, Scope, price and fee are unchanged. Extend exact named-parent validation from two to three while retaining duplicate/missing/self/cycle checks. All parents share the existing single50% familiarity cap; queued research is not ownership.

Score System remains its existing root. The optional Inventory System→Score System clarification is unanswered; neither that link nor founding-roster changes are authorized here. General current-project Design-ancestor gating for Alpha draws and other upgrade rules remain separate OPEN work.

Keep five Gameplay roots inward-aligned and preserve the common212px lattice. Combat occupies the upper branch, Timer/Categorized Scores/Power-Ups the middle, and Score/leaderboards below. Inventory row8 and Controls row9 keep the old total map-height envelope. Three-parent navigation fits its selected card and all three animated, directly clickable links at900/1152/1280. Other category layouts remain intact.

Historical ownership, accepted paid queues, payments, rosters and frozen projects stay exact, without retroactive parent grants. Recognize only the recorded predecessor catalog/source pairs. No finance, Bank, Core standard, AI policy or Studio-only Continue change.

[Source, tests, retained failures and limits](../logs/2026-10-29-gameplay-restoration-v1.md). Late Research latency remains FAIL/OPEN; these checks do not establish final balance or release acceptance.
''')

write(root/'docs/codex/logs/2026-10-29-gameplay-restoration-v1.md',f'''# Gameplay restoration —2026-10-29

Started2026-10-28, closed2026-10-29. Branch `{branch}`, HEAD `{head}`; inherited edits and `.codex-godot-temp` preserved. No commit, push or export. Direct user approval selected the three trial rows in [the adopted design](../design/gameplay-feature-restoration-2026-10-29.md); Inventory→Score remains unanswered, so Score remains a root.

Seven runtime files changed: feature_store_ledger.json; feature_store_catalog.gd; studio_checkpoint.gd; rival_world_checkpoint.gd; feature_store.gd; feature_store_layout.gd; feature_store_map.gd. Added Timer/Inventory/Categorized Scores, exact three-parent acquisition and unchanged Alpha Power-Ups as its child, bounded layout/three-link navigation and precise prior-catalog compatibility. Preserve old paid queues and frozen supply. [Owned byte hashes/diffs](../findings/gameplay-adoption-20261028-v1/owned-source.json). Baseline `{baseline['runtime_identity']}` → `{identity}`.

Final mechanics51/0, funded actual-play56/0 (46 commands), unfunded replay38/0 (36 commands/two releases), grid74/0, cold-world7/0, native three-parent129/0, refresh12/0, retained Audio143/0 and prior Gameplay119/0 pass. Research and Store integration pass. Funded route actually plays/exhausts the additions and Power-Ups; both campaigns replay exactly. Native900/1152/1280 link clicks use actual pointer events;900px capture inspected. Shared final source also passes138 live/headless boundaries over three seeded routes after isolated test-writer repair. No universal parity claim.

RED missing-card checks and selected-card clipping failures retained. Initial button-only success did not prove card visibility; the later stronger bounds/pointer checks verify it. Original console executable disappeared; existing GUI Godot4.7.1 binary supports both headless and native modes. No install/escalation needed. Read-only review found no actionable defect; [review](../findings/gameplay-adoption-20261028-v1/REVIEW.md). Exact commands, receipts and warnings in [verification.json](../findings/gameplay-adoption-20261028-v1/verification.json). Late Research latency remains FAIL/OPEN; no new timing, balance, build or release result.
''')

write(root/'docs/codex/logs/2026-10-29-scope-confirmation-v1.md',f'''# Incomplete Project Scope confirmation —2026-10-29

User requested the existing under-Scope Alpha→Beta confirmation match the current menu design. Branch `{branch}`, HEAD `{head}`; inherited dirty edits and `.codex-godot-temp` preserved. No commit/push/export.

Only production change: `scenes/phases/alpha_phase.tscn` attaches the existing `ui/quit_confirmation.gd` to UnderScopeDialog and uses its680×300 surface. Shared chamfered dark panel, fonts, orange Confirm, Cancel, header× and0.24s slide-in replace stock gray chrome. Exact title, four-line warning, Confirm/Cancel labels and all Alpha callbacks/Scope rules remain. Scene SHA `{scene_sha}`; script/data runtime remains `{identity}`. [Owned scene diff](../findings/scope-confirmation-20261029-v1/owned-scene.diff).

RED50 checks/12 expected style failures retained. GREEN74/0 headless and74/0 native at1152×648 and1280×720; both rendered captures inspected. Cancel, Escape and× preserve project/hand/RNG; Confirm finalizes once with actual Scope1 and stale callbacks cannot duplicate. Existing Alpha finalization and149-assertion arrears regression pass, preserving finance/debt/clocks and free-exit rules. Three seeded campaigns pass138 live/headless boundaries with exact replay.

Initial broader parity launch failed `writer_busy`: its debug fixture used production port62741 despite a private profile. Test-only repair selects the existing TestStore when PN_CHECKPOINT_TEST_PORT is supplied; production locking/validation unchanged. Failed receipts retained. Existing fixture ObjectDB/artwork warnings remain. [Exact commands, hashes, captures and checks](../findings/scope-confirmation-20261029-v1/verification.json). Focused local acceptance only; existing EXE/ZIP and late Research OPEN status unchanged.
''')

game_entry = '**2026-10-29 Gameplay restoration — IMPLEMENTED locally; values ACTIVE/TRIAL.** Added approved Timer System, Inventory System and three-parent Categorized Scores, with existing Alpha Power-Ups as its child. Centralized roots, shared familiarity cap, exact old paid queues/frozen projects and three-link native navigation are preserved. Score System remains a root while the optional Inventory link is unanswered. Focused mechanics, actual play/exhaustion/replay, old/current saves and native checks pass; final seeded comparison passes138 boundaries. [Design and remaining gates](design/gameplay-feature-restoration-2026-10-29.md) · [source/checks](logs/2026-10-29-gameplay-restoration-v1.md). Late Research remains FAIL/OPEN; no export/commit/push.'
scope_entry = '**2026-10-29 Incomplete Project Scope prompt — COMPLETE locally.** Uses the shared animated confirmation panel with matching fonts/buttons and unchanged warning/Alpha rules.74 headless/74 native checks, Alpha finalization/arrears and138 seeded live/headless boundaries pass; both supported native captures inspected. [Source and limits](logs/2026-10-29-scope-confirmation-v1.md). Existing EXE/ZIP unchanged.'
for name in ['CURRENT_STATE.md','TODO.md']:
    p = root/'docs/codex'/name
    prepend(p, scope_entry+'\n\n'+game_entry+'\n')
    content = p.read_text(encoding='utf-8')
    if name == 'TODO.md':
        content = content.replace('The Audio subset is adopted per the2026-10-28 log above. Resolve other upgrade replacement and old-save/project supply behavior; current-project Design-play gate for Alpha draws; three-parent Categorized Scores, Timer/Inventory and Power-Ups links; and new-card values, years and roster migration.', 'The Audio subset and the approved three-card Gameplay/Power-Ups subset are adopted per the logs above. Remaining work: optional Inventory→Score link pending user clarification; other upgrade replacement and old-save/project supply behavior; current-project Design-play gate for Alpha draws; and any other new-card values, years or roster migration. Score remains a root meanwhile.')
        write(p, content)
prepend(root/'docs/codex/design/feature-store-progression.md',game_entry.replace('(design/','(').replace('(logs/','(../logs/')+'\n')
prepend(root/'docs/codex/design/ui-design-system.md',scope_entry.replace('(logs/','(../logs/')+'\n')
prepend(root/'docs/codex/DECISIONS.md','## 2026-10-29 — approved Gameplay restoration subset\n\n'+game_entry+'\n')
print(json.dumps({'runtime':identity,'scene':scene_sha,'owned_runtime_files':len(owned),'passing_receipts':len(game_receipts)+len(scope_receipts),'branch':branch,'HEAD':head}))
