# Fresh-context read-only review — 2026-10-31
Reviewer: engine_phase1_review. No edits/tests by reviewer. Parent implementation owner retained.

Important findings: global-only familiarity validation rejected other-engine credits; era validation recognized only old paid queues; completed Contract eligibility checked only global legacy ownership; F8 unlock bypassed initialized registry. Additional source concern: dropped current frozen engine capacity could silently restore a custom engine with zero capacity.

Resolution: engine implementation union is used only for immutable credit/Contract provenance; current runtime Contract admission uses selected committed supply. New era receipts keep year/release gates and scoped prerequisite admission proofs. Debug rebases only the selected proprietary library in an explicitly nonpersistable sandbox. Current world snapshots require frozen engine fields; unknown custom engines cannot fall back to zero capacity. Assertions and outcomes are recorded in later acceptance runs; this review alone is not PASS evidence.
