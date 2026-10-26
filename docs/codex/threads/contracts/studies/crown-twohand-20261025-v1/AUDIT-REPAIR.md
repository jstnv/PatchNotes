# Audit correction — 2026-10-25

The first `audit.py` invocation exited1 at line113, `mean-4521 plan uses present view`, after both controls passed. Raw PLAN `cores` and `priorities` are enum-keyed dictionaries serialized as `{"0":...,"1":...,"2":...,"3":...}`; the audit incorrectly compared the former with an array and would also have indexed priorities as an array. Inspection confirmed first Scope0, all four Cores0, and identical PLAN/HAND visible cards. GDScript reads integer enum keys correctly; no policy or simulation failure occurred.

Retained original audit in `audit-failed-v1.py`. Corrected only the Python decoder: assert exactly the four expected keys, normalize in explicit category order. Raw logs, fixed policy/config/plan, source and cases unchanged; no rerun or favorable-seed substitution. Initial command: bundled Python `docs/codex/threads/contracts/studies/crown-twohand-20261025-v1/audit.py`. Corrected rerun command/exit/log are retained as `audit-verified-*`.
