# Merge momentum and final score hop — 2026-10-27

User request is the spec: inherited merge speed on outward mitosis, followed by an upward hop and downward exit like Outta Pocket. Earlier no-input authorization applies; no design questions needed.

Architecture: keep pure music-clock sampling in card_score_floats.gd. No frame-integrated physics, new timer, gameplay resolution or changed global deadlines.

Rulings:
- Preserve speed magnitude, redirect along each outgoing branch. First gather has four different speeds: use their equal-weight mean for the symmetric sum/multiplier pair. After that pair merges, each final branch inherits its shared incoming speed.
- Use a distance/duration-aware curve with the inherited initial speed and zero arrival speed. Remain monotonic and bounded even at high speed; slow into the fixed card/spread target.
- Remove the prior second-merge result hold (2–2.25 subdivisions): four-way mitosis now starts at 2 immediately, still arrives at 3. Keep the first spread/hold/merge (0.5–1 /1–1.5 /1.5–2), readable final hold3–4 and exit/HUD4–5.
- Outta Pocket _animate_score_award uses a22px upward hop (quadratic-out,0.16s) then quadratic-in drop (0.26s). Normalize that ratio to our one-subdivision exit and end fully behind the card border.

Execution (inline):
1. Capture real predecessor Studio/world and exact before source. Add failing tests for physical speed continuity at both Balanced merge/split boundaries and a visible22px exit hop.
2. Implement bounded inherited-speed spreading and the reference-shaped hop. Add the exact predecessor identity to the existing presentation compatibility allowlist; preserve all validation/RNG.
3. Focused headless/native verifiers, limited native frames, soundtrack grid checks, exact predecessor/cold restore and source audit. Retain failed receipts. No export/commit/push.
4. Update core/studio presentation record, current state/queue, and dated local session log with evidence and limits.

## Completion ledger

- [x] Exact predecessor capture and before source; corrected monotonic test probes fail27 behavioral assertions on the old motion.
- [x] Inherited-speed spreading and exit hop implemented; exact predecessor allowlisted without weakening validation.
- [x]385 headless/385 native focused checks,3503 timing,10 exact restoration checks;42 frames and source audit retained. Independent scoped review: no actionable findings.
- [x] Design/current state/TODO and dated session log updated; CRLF-aware scoped whitespace passes. No export, commit or push.
