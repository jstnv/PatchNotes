# Retained audit-script failure, 2026-10-18

Command: `python docs/codex/threads/ai-competitors/audit_g4_rival_world_v1.py --original docs/codex/threads/ai-competitors/sims/g4-synergy-20261018-v1-world01 --candidate docs/codex/threads/ai-competitors/sims/g4-synergy-20261018-v6-world01 --output docs/codex/threads/ai-competitors/sims/g4-synergy-20261018-v6-world-audit01`

Exit 1 before any audit output: `TypeError: unsupported operand type(s) for /: 'str' and 'int'` while reading the readable Studio checkpoint's string-encoded `review_tenths`. The simulator runs and the maintained world verifiers had already passed; this was an analysis parser error. The original script remains, and `audit_g4_rival_world_v2.py` explicitly casts the readable integer fields. Its new output is [world-audit02](../g4-synergy-20261018-v6-world-audit02/audit.md), 24/24 checks.
