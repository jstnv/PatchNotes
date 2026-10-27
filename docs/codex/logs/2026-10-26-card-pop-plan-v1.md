# Card charge/pop plan

User request: larger scaling bounce, quick charge before the scoring pop, small outward particle burst. Presentation only; retain the existing music reference, rise/score/grounded schedule,140 activations/minute, authoritative once-only action and synergy sequence.

Implementation choices:60ms anticipation to94% scale within the existing rise half;114% peak at the original score event; settle during the existing fall half. Twelve small deterministic pixel sparks, up to0.30s, sampled from the same music cursor; no gameplay or global RNG. Base plays and existing specialization re-triggers receive the effect; redraw/removal and victory wave do not create scoring particles. No extra bounce or timing interval.

Files: modify `patch-notes/scripts/ui/hand_presentation.gd`; add focused `ui/card_play_burst.gd`; add `debug/verify_card_pop.gd`; exact predecessor source compatibility in `market/rival_world_checkpoint.gd` only after captured pre-change proof.

- [x] Capture pre-change real player/world pair; test missing charge/pop behavior before implementation.
- [x] Implement bounded music-sampled sparks and scale anticipation/pop/settle; verify pause, resume shift, low FPS, cancel, no scoring duplication/RNG changes.
- [x] Run maintained soundtrack/Search-first/tutorial checks, native captures and exact predecessor cold restore.
- [x] Persist source-pinned results and update current work records. Preserve dirty edits/temp; no commit/push or requested player rebuild.
