from pathlib import Path
import json,hashlib,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'design-logs/task31-v1'
DEST=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs')
BUNDLE=DEST/'Task31 Studio Traits Selection v1'; BUNDLE.mkdir(exist_ok=True)
gate=json.loads((OUT/'final-gate.json').read_text(encoding='utf-8')); assert gate['passed']
render=json.loads((OUT/'render.command.json').read_text(encoding='utf-8')); assert render['exit']==0 and not render['errors']
before=json.loads((OUT/'source-before.json').read_text(encoding='utf-8'))
changed=[p for p,h in before['files'].items() if (ROOT/p).exists() and hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=h]
new=['scripts/studio_traits.gd','scripts/debug/verify_studio_traits.gd','analysis/task31_verify_v1.py','analysis/task31_layout_probe_v1.gd','analysis/task31_report_v1.py']
text = """PATCH NOTES — TASK31 STUDIO TRAITS SELECTION v1
STATUS: COMPLETE first selection pass locally. Preview-only effects are intentionally not shipped bonuses.
SOURCE: main e054791d0348d90faf70e9d827892c351fa018bc (Bank), with verified local Task33 and existing retained-pool/animation work. Task29 is committed at HEAD. Cached origin/main matches; fresh remote query failed because git remote-https is unavailable. No commit/push performed. No AGENTS.md found in repository/ancestors. .codex-godot-temp and pending gameplay changes preserved.
AUTHORITY: refreshed live Task31, cumulative §§56/63/68/69, Design and Progress Archive (working V1, 2026-09-29), Task22/Task29/Task33 evidence. New Task31 explicitly permits labeled selection-only previews, superseding the archive's older prohibition on inert choices. The archive still calls positive prices/effects and Unknown Name/Expensive Lease packages unresolved; Task22 shortlists are unapproved. No invented price or bonus.

PLAYER FLOW / IMPLEMENTED
Start Game -> name and separate required Genre specialty -> Studio Traits -> final confirmation -> Studio. One manually selected Family Funding, Cult Following or Publisher Connections background; no default, duplicates or stacking. Genre continues to grant exactly its existing automatic roster, with no trait point cost or initial purchase/Scope cap.
Six optional secondary previews: Resourceful, Lean Production, Studio Buzz; Student Loan, Expensive Lease, Unknown Name. Stable IDs, concise purpose, pending prices and explicit inactive status shown. At most two positive and one negative preview. Student Loan describes the fixed96-boundary duration and working $10/+2 but has NO refund/dues in this pass. All previews spend/refund zero active points. Thus4 points remain regardless of preview selection.
Accepted conversion is WIRED:4 unspent points x$50 = $200 once, separate from $5,500 base capital. New player-created studios begin with $5,700. Maximum helper conversion is $300; negative point input rejects and large values cannot overflow. A stable studio_trait_unspent_points_v1 financing receipt goes through the pure authoritative finance planner during atomic creation. This is capital, not operating profit or loan proceeds; no credit gain. Confirmation commits identity, ownership, cash, receipt and choices before signals; duplicate, failed or stale confirmation cannot pay twice. Month1 rent remains exactly $500 at cycle2. No sales/lifespan/rent/Review price retune.
Background and secondary effects are NOT WIRED: no Family bonus cash, Cult fans, Publisher reward/access, Store discounts, production discounts, Awareness modifiers, rent surcharge, credit overlay or Student Loan bills. Only the existing Genre roster and accepted unused-point conversion affect gameplay. UI says this before confirmation and in Studio. A future activation must not retroactively apply a preview's effect or create historical debt without an explicit rule.

OWNERSHIP / PERSISTENCE
RunState owns a defensive version1 selection snapshot: background_id, canonical ordered secondary_ids, effects_mode, starting/spent/refunded/remaining points, confirmation payout. Creation snapshot adds studio name, specialty, base capital and confirmation flag; editor capture includes it and the catalog source hash. Scene reconstruction reuses this state without regranting. A fresh RunState clears it. Exact typed binary checkpoint roundtrip tested. Durable disk saves and a trusted loader remain deferred; JSON diagnostic capture is not a save implementation.
Legacy set_studio_name remains for earlier-run/no-trait fixtures and historical route replay, granting exactly $5,500 without a fabricated background. Live Start Game uses create_studio and cannot skip the new required choices. Task32's documented pre-Task31 $5,500 source snapshot remains a valid matched comparison; it is not mislabeled as post-conversion player funding.

VERIFICATION
GATE
verify_studio_traits covers all24 background/Genre pairs, unknown/missing/duplicate/over-cap selections, immutable copy, exact receipt/profit/credit, point cap/overflow, no preview loan bill, duplicate confirmation, first due, cancellation, reconstruction and fresh reset. Active positive spending/refunds cannot be tested as playable because no such effect is approved/wired; invalid negative totals and conversion cap are pure fixtures. Screens at1152x648 and1280x720 rendered through Windows GL compatibility and visually inspected: Traits, final summary, Studio identity. No claim of human graphical input or exported smoke.
Initial full gate exposed old UI fixtures assuming the prior one-step creation and $5,500 total. Adapted them to explicitly choose a background/confirm; no gameplay assertions removed. An older900x600 fixture confused physical window with logical canvas; now explicitly sets its matching content scale. A real render caught initial zero-width autowrap inflating Studio to4988px tall; bounded label widths now keep its title/identity and actions visible. First startup-receipt implementation accidentally retained planner envelope rather than its ledger; failing finance/action tests caught it and the final source uses receipt.ledger. Initial failures retained separately; final gate passes.

FILES
FILES_LIST
New catalog/verifier UID companions generated by Godot. Existing verify_card_motion pending motion changes were retained; only the new creation step was added. Other original animation/retention/Store source remains unchanged.
COMMANDS: Python -B analysis/task31_verify_v1.py; same --render. Exact Godot4.7.1 executable, arguments, isolated APPDATA/LOCALAPPDATA profiles, exits and marker classifications in command JSON/final-gate. Source before/final hashes and working diff retained. Raw evidence: patch-notes/design-logs/task31-v1; portable copy: New Data Logs/Task31 Studio Traits Selection v1.
DEFERRED: all background/secondary effects and unresolved point prices, Student Loan producer, durable saves, loan issuance, human acceptance/exported interactive smoke, earlier free Alpha-exit finance guard issue. Next queue task: refresh Task12 settings/input/audio gate. Nothing committed or pushed.
"""
text=text.replace('GATE',f"Final headless editor import plus all {len(gate['results'])-1} maintained suites PASS; {sum(r['assertion_passes'] for r in gate['results'])} PASS markers, zero unexpected errors, diff-check exit{gate['diff_check']}. Render exit0, zero error markers.").replace('FILES_LIST','\n'.join(changed+new))
log=DEST/'Patch Notes - Task31 Studio Traits Selection v1.txt';log.write_text(text,encoding='utf-8')
for f in OUT.rglob('*'):
 if f.is_file():
  d=BUNDLE/'evidence'/f.relative_to(OUT);d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,d)
for rel in changed+new:
 f=ROOT/rel;d=BUNDLE/'source'/rel;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,d)
print(log)
