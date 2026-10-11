# Simulation Engine design thread

Started 2026-10-10. The initial architecture brief was documentation-only. The user subsequently authorized the first extraction; this folder records that bounded implementation.

- [Proposal review and additions](REVIEW-v1.md)
- [Prompt for the implementation thread](HANDOFF.md)
- [Session log](2026-10-10-session-log-v1.md)
- [Source-pinned architecture assessment](2026-10-10-architecture-v1.md)
- [Architecture audit session log](2026-10-10-session-log-v2.md)
- [Source manifest](source-pin-2026-10-10-v1/manifest.json)

- [M1 implementation and verification](2026-10-10-extraction-m1.md)
- [M1 session log](2026-10-10-session-log-v3.md)

- [M2a Design-hand command and parity](2026-10-10-extraction-m2a.md)
- [M2a session log](2026-10-10-session-log-v4.md)

- [M2b overflow repair and Alpha-hand command](2026-10-10-extraction-m2b.md)
- [M2b session log](2026-10-10-session-log-v5.md)

- [M2c Beta-hand command](2026-10-10-extraction-m2c.md)
- [M2c session log](2026-10-10-session-log-v6.md)

- [M2d development actions, boundaries and replay](2026-10-10-extraction-m2d.md)
- [M2d session log](2026-10-10-session-log-v7.md)

- [M3a Launch settlement and multi-project campaign commands](2026-10-10-extraction-m3a.md)
- [M3a session log](2026-10-10-session-log-v8.md)

- [M3b Contracts, Studio actions and checkpoint continuation](2026-10-11-extraction-m3b.md)
- [M3b session log](2026-10-11-session-log-v9.md)

- [M4 campaign parity and batch testing foundation](2026-10-11-extraction-m4.md)
- [M4 session log](2026-10-11-session-log-v10.md)
- [M4 acceptance and measured pilot](m4-v1/acceptance.json)

- [Run simulations from any thread: usage, policies, replay and continuation](USAGE.md)
- [M4b self-service runner and measured efficiency](2026-10-11-extraction-m4b.md)
- [M4b session log](2026-10-11-session-log-v11.md)
- [M4b acceptance](m4b-v1/acceptance.json)

- [M4c paired studies, measurements and reports](2026-10-11-extraction-m4c.md)
- [M4c session log](2026-10-11-session-log-v12.md)
- [M4c acceptance](m4c-v1/acceptance.json)
- [Store research/defer template](examples/store-study.md)

- [Independent design versions, simultaneous runs and adoption handoffs](VARIANTS.md)
- [M4d stress, expanded parity and failure reproduction](2026-10-11-extraction-m4d.md)
- [M4d session log](2026-10-11-session-log-v13.md)
- [M4d acceptance](m4d-v1/acceptance.json)

Status: M1, M2a–M2d and M3a–M3b are implemented locally. M4 provides native/headless campaign comparison, bounded policy/batch execution and measured pilots; M4b supplies isolated self-service runs, exact replay and Studio continuation. M4c adds matched studies and measurements. M4d supplies concurrent thread-owned candidate versions, source/evidence handoffs, four seeded stress routes and legal-Studio failure reduction. Current focused native/headless coverage matches232 boundaries; two private versions ran simultaneously and replayed72 commands/74 measurements. Continue remains Studio-only. Competitor policy gates, M5 shared-world scheduling and actual AI population scaling remain OPEN. These experiments do not approve AI balance or strategy values. TODO documents the user-authorized version handoff workflow; no synthetic candidate was queued for adoption.
