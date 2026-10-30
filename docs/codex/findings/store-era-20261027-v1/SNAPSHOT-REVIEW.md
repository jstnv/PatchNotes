# Focused detached-snapshot optimization review — 2026-10-27

Read-only independent review by save_snapshot_review under the requesting-code-review skill, comparing the recorded performance-before files with the current two-file delta. No edits or Godot execution by the reviewer. No actionable correctness issue found.

Studio snapshots still deep-copy native values; schema encoding rebuilds development containers; observation history already copies nested values; Legacy encoding begins with a deep copy. Explicit archive/market/origin copies cover the remaining live containers. The shared current adapter is used only on the main thread and is not stored in the worker; the worker freshly encodes and validates current executable data. Previous payload remains deep-copied. Priming the cached current revision at binding introduces no identified lifecycle or error regression.

The reviewer noted a nonblocking test coverage limit: live→DTO mutations did not include active development project/hand containers. Those mutations and an explicit exercised-probe assertion have now been added; updated18-check verification passes, including a positive active-development probe assertion. Performance, gate completion, unrelated shared work and release readiness were deliberately not judged.
