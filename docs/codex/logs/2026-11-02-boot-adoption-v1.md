# 2026-11-02 — approved boot reveal

On `main` / HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`, integrated the source-pinned v10 boot screen with the current Dream Groove menu transport, circuits and button wave. Preserved prior dirty work and `.codex-godot-temp`; no commit/push/export. [Source, checks, retained failures and limits](../findings/boot-adoption-20261102-v1/RESULT.md).

Final boot 18/0, native keyboard/layout 11/0, pointer 1/1, and preceding paired save 4/0. Earlier on the same integration, audio synchronization 3503/0, wave 49/0, menu analyzer 33/0 and loading-cover lifecycle 5/0 passed; private new-save 18/0 used a test-only non-socket lease due to sandbox TCP restrictions. Actual-device listening/controller and exported build are not verified. The later Main Menu entrance remains OPEN.
