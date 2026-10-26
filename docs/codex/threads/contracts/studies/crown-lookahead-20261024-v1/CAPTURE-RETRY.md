# Retained capture retry

2026-10-24. Initial `controls/` capture exited1 with `Canonical source changed while recording drift; retry in a new output`. It stopped before import/experiment execution; no gameplay result exists in that folder. The failed report and partial manifest evidence are retained.

Reissued the identical controls command to the new `controls-v2/` directory, without modifying variant project, policy, seeds, recipes or limits. Analysis points to this second capture; the first remains a capture failure, not nine failed campaigns. Canonical work by another thread is preserved. This concurrency retry does not bypass the runner's source fencing. Its outcome is recorded in the final finding.
