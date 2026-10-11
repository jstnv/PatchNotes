# v13 repair v4

The first v13 attempt failed to parse. Repair v2 omitted the native Game 5 priority setup. Repair v3 used the right setup but called `commit_draft()` even after predevelopment had already committed it. Their command, native traces and stops remain preserved. This revision changes only the analysis route's Game 5 conditional: set priorities and commit the overlay together **only if** initial planning is active, exactly as the pinned native Starwave route does. It retains the [same three inputs, two arms, source and calendar endpoints](../PREDECLARATION.md).

This revision has its own disposable project, profiles and manifest. Run `prepare`, `import`, `parse`, then Action/Starwave as the full-route gate. If that arm reaches 75/77/79, run the five remaining arms. The [repair-v2 command list](../repair-v2/README.md) applies with `repair-v4` in each path. No failed output is overwritten.

All six final arms reached 75/77/79 with valid finance and clean source/driver checks. The [independent audit](audit-summary.json) passed 32,640 checks. The output remains bounded evidence; it does not approve a Starwave advance or final tuning.
