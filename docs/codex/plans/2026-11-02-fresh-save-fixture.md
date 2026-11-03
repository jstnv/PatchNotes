# Fresh-save fixture timeout implementation plan

Execute inline with systematic debugging/TDD and one fresh read-only review. User explicitly authorizes no-input implementation, acceptance and Git publication.

- [x] Reproduce actual old timeout and pin its asynchronous setup stage. Add focused timeout-guard regression where useful; no game behavior changes.
- [x] Central bounded60s setup wait, progress/failure diagnostics, aligned loading and multi-save suite bounds. Preserve action/focus assertions and fail on stuck transitions.
- [x] Headless/native maintained Store/focus/loading and scoped save/RNG acceptance. Retain failures, independent review, dated log/current/TODO updates, narrow commit/push with verified remote equality.

Observed: warm baseline focus22/0; controlled real initial publication+21s reliably failed old20s helper, then passed8/0 with same setup under new bound. Multi-save headless radial147.687s would exceed old110s suite watchdog; all255 checks pass with per-case-aware bound. Native radial255/0; loading18/0 headless. Stuck setup still asserts at60,007ms; initial guard fixture had an extra caller sentinel after the expected assertion, retained and superseded by strict guard. Preserve dedicated loading verifier original LF format; remaining native/loading/focus/save checks use final source.

Final acceptance580 positive checks plus48 audit;2 expected negative guards. Production identity unchanged; current native full-source fence exact. Review/Git receipt recorded with completion.
