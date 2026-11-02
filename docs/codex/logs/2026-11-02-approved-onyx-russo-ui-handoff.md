# Approved Main Menu / Studio visual adoption handoff, 2026-11-02

The user accepted the revised font preview and explicitly requested publication to the TODO for PN Implementation. Status: USER-ACCEPTED visual candidate; QUEUED for reconciliation and adoption in the main checkout. This handoff does not itself change shared runtime code.

## Accepted version

Adopt the Onyx `#141519` / Deep Indigo `#211B38` / Electric Indigo `#6F42FF` / Tropical Mint `#5EF2C2` / Warm Cream `#FFF3E2` Main Menu and Studio presentation, with the latest **Russo One** typography. Tiny5 was rejected for these screens. Display headings, main/root buttons and large values use Russo One; readable IBM Plex body/metadata remains. Main/primary buttons are 28px, long Studio root labels 24px. Keep the original logo alongside the separate recolored asset. Use native controls/theme resources, live audio metadata and real Studio values, not a mockup background or placeholder economy values.

Candidate root: `C:/Users/64jus/.codex/worktrees/613f/PatchNotes`, detached baseline `3a61522f18db7a2bae892cb8c5be1fee68cd4100`, with existing uncommitted UI work. Source files and evidence are directly accessible there:

- [Visual implementation and file inventory](C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/logs/2026-11-02-onyx-indigo-mint-ui-candidate-v1.md)
- [Accepted font revision and exact checks](C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/logs/2026-11-02-onyx-font-readability-v2.md)
- [Base source manifest](C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/findings/onyx-indigo-mint-20261102-v1/source-manifest.json) and [font-only delta](C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/findings/onyx-font-readability-20261102-v2/source-delta.json)
- [Accepted Main Menu preview](C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/findings/onyx-font-readability-20261102-v2/main-menu-1280.png) and [Studio preview](C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/findings/onyx-font-readability-20261102-v2/studio-phase-1280.png)

Current `patch-notes/resources/ui/onyx_theme.tres` SHA-256: `8fbe1dff09cd2fbb038c3c83f3db17d53beeeec0a457e78a07556337ba7a68b4`. Russo One font SHA-256: `bc0abcc660bd8b7ad3000ecb2898a27c58a29a50f7ec81652fa12e75148d09df`; full OFL license and pinned Google Fonts provenance accompany `assets/fonts/russoone/`. Use this theme hash instead of the old hash in the base manifest. No runtime scripts changed in the font revision.

## Reconciliation with current implementation

Shared checkout inspected at branch `main`, HEAD `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`, with newer local work. PN Implementation's latest Engine task is completed/idle. Its CURRENT_STATE/TODO already record adoption of four Studio groups and floating Feature Store controls. Those are completed dependencies, not new tasks to repeat.

Apply the presentation delta to the current shared implementation. Do not copy older whole Studio/Engine/gameplay files from the candidate or restore its retired global Feature Store button. Preserve current engine-scoped Feature entry, visible Implementation Queue/Implement, Skill Tree and 25/30/35 Scope behavior; the current four groups, release gates, common Back, motion and focus; and the newer Dream Groove/Echo Reverb menu/loading and six-track Studio audio transport. The candidate's screenshot track is its actual older Crunch Time snapshot, not a request to replace the shared soundtrack.

The live overview is shown when no companion group is open and replaced by the selected companion. Its decorative desk is presentation only. Next Bill explicitly displays the current rent installment; existing cash/fans/finance and other HUD actions remain.

## Acceptance

Candidate evidence: the visual implementation recorded 575 focused checks; the final font revision reran 83 native presentation and 103 native Studio navigation checks, all passing. These are isolated-candidate results, not canonical verification. Rerun applicable native checks after reconciliation at 1152×648, 1280×720 and 1920×1080, including long-label fit, contrast/disabled states, keyboard/controller focus, destination/Back behavior, real values, save detection/Create/Continue, and the current audio/loading lifecycle. Preserve current Engine/Store checks and old-save behavior. Human/device/export gates remain separate; no commit, push or rebuild is requested by this queue update.
