# Audio pool discrepancy intake — 2026-10-28

User reported that the Feature Store Audio pool no longer resembles the earlier desired pool. Read-only investigation; no gameplay, UI, catalog, TODO, export, commit or push changes.

- Branch `main`, HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`; inherited dirty worktree preserved, including `.codex-godot-temp`.
- Read CURRENT_STATE, TODO, repository README, Feature Store design and Proposals 015/028 with Handoff 023. Inspected status/diff and current layout/catalog/UI source.
- Exact static comparison: current Audio lane, byte-snapshotted pre-central-root lane and HEAD all enumerate the same six IDs: `8_bit_sound`, `recorded_sounds`, `8_bit_music`, `16_bit_music`, `sound_effects`, `music`. All six card records match HEAD exactly. Latest central-root change moved placement and suppressed cross-category drawing; it did not remove Audio cards.
- Proposal 028/Handoff 023 describe the fuller requested Audio branch: 8-Bit Sound root, distinct new 16-Bit Sound, Main Theme, Recorded Sounds, Multiple Soundtracks, Instrumental Sounds and Dynamic Sequencing, with existing Music branch handling to settle. New cards are absent from canonical catalog. This is an implementation/design-scope mismatch, not evidence of recent deletion.
- Explained the missing larger branch and acknowledged that reporting the bounded overhaul complete did not make that limitation clear enough. No speculative card values, phase choices or save retirement adopted from this complaint.
- Checks: static list comparison and six parsed-record equalities PASS. No runtime test needed or run for this read-only finding. Follow-up: reconcile the user's intended Audio pool before a narrow restoration/content change; preserve centralized roots and no cross-category arrows.
