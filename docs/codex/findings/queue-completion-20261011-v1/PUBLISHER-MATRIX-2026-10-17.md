# Neon and Starwave exported-check closeout

2026-10-17 (America/Los_Angeles). **The requested remaining Neon/Starwave presentation checks PASS on the retained export. Latest integrated-source acceptance remains OPEN.** No gameplay, payout, scoring, balance or checkpoint rule was changed in this pass.

## Exact scope and source

Dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. The tested binary is the retained 2026-10-11/12 Godot 4.7.1 export: EXE SHA256 `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`, PCK SHA256 `2215f0ee1bd7c663b05577204aad8866a379c24abdc3e8215a3d98dcd27aca19`. Its 281-entry package and source are pinned by the [135-suite gate](../two-parent-store-20261011-v1/release-gate/). This continuation did not rerun that gate or rebuild the binary.

[Current-source comparison](publisher-matrix-audit-20261017.json) verifies the publisher/Contract modules still match those export-source hashes. However, Gameplay, checkpoint coordinator/schema/hydration, development-session and Bank UI changes are newer; new AI shared-world/trial files are also outside that export. The concurrent integration was preserved. These tests cannot establish acceptance of those newer paths. `automated_pass=false` and `release_ready=false` remain recorded in the original gate; do not rewrite its historical result based on this bounded UI work.

All input was ordinary exported-game mouse/keyboard interaction through Computer Use, using isolated APPDATA/LOCALAPPDATA and Dummy audio. No player saves, cash, card data, RNG or offers were injected. Pending checkpoints were byte-exact copies of earlier ordinary-input Studio saves. [Profile origins](matrix-profile-origins.json) document the earlier matrix forks. The additional `neon-matrix-resume` profile copies `checkpoints/neon-completed/checkpoint.2.json`, SHA256 `9dd057270228c817705860c004a479057be507f5d8dbfc8ee6d96df9526be009`, at cycle15/$790.00; only display preferences were copied separately. The main-menu New Run confirmation was accidentally opened and canceled before Continue; the pending checkpoint and replay outcome remained intact.

## Presentation evidence

Numbers refer to the durable [capture index](captures/index.jsonl), which includes timestamps, window identity and PNG names. Earlier captures retain their original dates. Logical game sizes are 1280×720 and 1152×648; Computer Use's returned window screenshots are scaled captures including the window border.

| Publisher / surface | 1152×648 | 1280×720 | Result |
|---|---|---|---|
| Neon browser | 316–318, keyboard Back focus | 186 | PASS, Graphics focus and offer state readable |
| Neon chooser | 188 | 187, 319 | PASS; 187's filename incorrectly says Technology, but the visible focus is Graphics |
| Neon hand/progress | 189–192 | 320–321 | PASS, fixed targets and selected cards visible |
| Neon result/return | 193–194 | 323–324 | PASS; Enter returns to Studio at 1280, preserving $1,560 and20 Promotion |
| Starwave browser | 213–214 | 197, 333–335 | PASS; completed state and keyboard Back confirmed at1280 |
| Starwave chooser | 326–327 | 198 | PASS; keyboard Accept at1152, all three-hand/final-only/no-Promotion terms fit |
| Starwave hand/progress | 209 | 203–208, 328–329 | PASS; three hands, legal redraw and no early Contract payment |
| Starwave result/return | 210–211 | 330–331 | PASS; Enter returns to Studio at1280, preserving $2,240 and no Starwave Promotion |

This is the recorded mixed mouse/keyboard acceptance matrix, not a claim that every individual control was exercised by every input method at both sizes. No new clipping, focus or result mismatch was found. Crown's complementary retained-export result checks are already in314–315, with1280 result172–173; they were not repeated here.

## Replayed outcomes and cold Continue

Both profiles retain run ID `f4447cfb81304a74f9d20ec63c2f013e` from the original legal route, in separate isolated folders.

### Neon

- Accept at cycle15, $790.00; no advance or cycle charged. Frozen focus Graphics, target9; others2; Scope10.
- Hand1: Exploration, General Combat, Split Screen, Sound Effects. Cycle16, G/S/T/D =1/3/5/10, Scope7, $3,842.44 after the month's other activity.
- Hand2: Multiple Endings, 8-Bit Sound, Sprites, Enemies. Cycle17, G/S/T/D =10/8/10/13, Scope15. Completion100%; exactly156,000 cents paid once, banked Promotion20. Studio cash540,244 cents, Fans53.
- Enter from the result commits Studio. Fresh process12280 restores the same bytes (capture325), without receipt replay or lost Promotion.
- Completed and cold-restored `checkpoint.3.json` SHA256: `931fb331876c93317d5356b4752f6fd2e36a91406870dc9ea1b546b95c80226b`.

### Starwave

- Continue from cycle34, cash1,500,292 cents, Fans172. Zero-cycle, zero-cash acceptance via keyboard at1152.
- Hand1: General Combat, 8-Bit Sound, Enemies, Scrolling. Cycle35, G/S/T/D =2/5/10/5, Scope8; cash unchanged.
- Hand2: Multiple Endings, Controller, Power-Ups, Split Screen. Cycle36, G/S/T/D =2/6/20/13, Scope15; cash1,624,116 cents from monthly activity, with no Starwave receipt.
- Redraw Menu System, Technology Pass, Design Pass and Controls. Hand3: Sound Effects, Text, Graphics Pass, 4-Color Palette. Cycle37, G/S/T/D =9/8/21/13, Scope18; numerator112/112. Exactly224,000 cents paid once, no Starwave Promotion; cash1,848,116 cents, Fans185.
- Enter commits Studio. Fresh process23172 restores the same bytes (capture332); browser confirms completed and no reissued offer (333). Keyboard Back leaves cash and cycle unchanged (334–335).
- Completed and cold-restored `checkpoint.12.json` SHA256: `6a7f3207f91351c883fef03f7adf716bb28cdfc0a46206770a7e3ff312f889e3`.

Archives: `checkpoints/neon-resume-completed`, `neon-resume-cold-restored`, `starwave-matrix-completed`, `starwave-matrix-cold-restored`.

## Audit and comparison limits

- `audit_export.py`: **15,434 checks, 0 failures**, no runtime errors in the retained profile logs. Reconciles transaction sequences, exact cash, original bills/payments, credit, monthly accounting, payout IDs and Promotion.
- `audit_publisher_matrix.py`: **25 checks, 0 failures**. Confirms one final receipt per offer, exact cycle/cash, expected Promotion, byte-identical cold restores, retained EXE/PCK hashes and unchanged Contract/publisher modules.
- The first strict original-versus-replay comparison reported two failures, retained in `publisher-matrix-audit-20261017-order-sensitive.json`. Every differing payload path was the insertion order of `publisher_offers/.../state/exhausted`. `ContractState` stores this as a membership Dictionary (`contract_state.gd:26,99,208`); the checkpoint serializer preserves its insertion order (`studio_checkpoint.gd:90`). After sorting **only those exhausted-ID map rows**, the entire payloads match, including RNG, finance, result and all other list order. No save bytes were changed. These are equivalent completed outcomes from the same selected card sets, not byte-identical replay action-order claims.

## What is complete and what remains

**Complete at the retained-export scope:** the previously missing Neon1280 result/keyboard return, Starwave1152 chooser/keyboard acceptance and Starwave1280 result/keyboard return, both fresh-process completion restores, and reconciliation with the earlier both-size browser/hand/result captures. Earlier Crown/Neon next-launch Promotion, positive sales and later no-reuse; Crown acceptance/first-hand rollback; Starwave acceptance rollback/reacceptance and next-month rent/payroll/sales evidence remain valid at their recorded scope in this folder.

**Remaining:**

1. Rebuild and pin the integrated source after the concurrent AI/Gameplay/checkpoint/Bank changes settle; rerun the affected maintained gate and exported continuation/rollback smoke checks. C5/item23 and latest-source S4/S5 stay PARTIAL for this reason. The retained presentation matrix itself is no longer queued.
2. Starwave's retained next-month route includes rent/payroll/sales but no Bank loan; that specific combined Starwave/Bank service boundary remains NOT RUN. Exported failed-launch Promotion preservation was not observed; focused native checks remain the evidence for it.
3. B7's retained Bank and active-education distress/recovery/Continue plus inactive preview are complete at bounded scope. Human quote comprehension, explicit older-education/newer-Bank payoff, elapsed overdue-age interaction, and a refresh against newer Bank/checkpoint source remain separate gaps. Do not label B7 wholly complete.
4. Audible soundtrack/SFX, human Store/quote comprehension, clean-machine/assets acceptance and final balance remain separate. Dummy audio provides no audible evidence.
5. Newly queued Contracts definitions, Founder/ownership, Traits registry, three-Core adoption and AI integration are preserved in TODO; this publisher-check request does not complete them.

No commit, push or release-readiness claim.
