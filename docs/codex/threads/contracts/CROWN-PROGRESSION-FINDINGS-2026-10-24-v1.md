# Crown progression — current baseline and synthetic arithmetic v1

2026-10-24. **Bounded evidence, not Crown pilot approval.** [Pre-run plan](CROWN-PROGRESSION-PLAN-2026-10-24-v1.md) and [candidate design](CROWN-PROGRESSION-DESIGN-2026-10-24-v1.md). No new gameplay producer was implemented. Approved SideStreet P4 continues separately.

## Recommendation

Develop a two-hand Crown Reputation Brief using its existing weakest-Core completion and balance promise, then gate proposed commission/support access through Crown's own relationship ledger. Prefer minimum(completion,promise) to compounded multiplication for the first private candidate. Keep raw Core equality out of commissioned-game requirements; ordinary Genre ratios already produce unequal Cores in a successful game.

**Do not queue Crown implementation yet.** Current Crown discovery and cash work are reachable in this bounded route; useful standing from the new balanced Brief is not verified. Test that separately before choosing numerical terms or activating further publisher profiles.

## Exact source and inputs

Dirty branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. P2/P3 actual release-EXE acceptance was complete at intake; P4 was being integrated and not accepted as complete. The runner captured an intermediate current working source. It is not the final P4 source or a P4 acceptance claim.

| Identity | Value |
| --- | --- |
| Frozen project | `69d200df1ddbaeec56980040394311e5a738a6109f371b0baa8238c62299ab22` |
| Runtime mechanics | `bbff4dd696d6f89b3a2c539d449164bcc187bf8387d822e179e61690427ba7ec` |
| Baseline policy | `1ee14d9a22b0cbfc58a80a16e2f68db06e20aad33ddf1cab5e60124b99936b55` |
| Runner | `65bdf6c5eb4a47af829283a0b07d4b78ad45e8a95139607b96a613d6ffbf9193` |
| Godot executable | `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef` |
| Final state / exact replay | `0b5368aafb1866557b8b3262e276cbdc1ed9cccf9dc756a42da56042f63ac61d` |

[Selected intake hashes](studies/crown-progression-20261024-v1/input-source-hashes.json), [input](studies/crown-progression-20261024-v1/baseline.json), [unchanged copied policy](studies/crown-progression-20261024-v1/baseline-policy.gd), [analysis and raw hashes](studies/crown-progression-20261024-v1/baseline-summary.json), [run receipt](studies/crown-progression-20261024-v1/baseline-run-report.json), [exact replay receipt](studies/crown-progression-20261024-v1/baseline-replay-report.json).

One fresh legal Action/Cult Following Studio, seed4417; ordinary research and visible candidate choices from the existing v4 policy. Four releases,125-command ceiling,240-second runner phases. Two later games intentionally use only one hand per phase. No cash/cards/unlock injection, player save or source-identity substitution. This is a single-Studio baseline, not an active multi-rival market or a matched publisher-value study.

Full frozen source/import/profile/tapes and checkpoint remain in [persistent raw evidence](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-progression-20261024-v1>). Compact records remain in the repository; this external directory is raw simulator storage only.

## Current-behavior result

PASS:85 accepted commands, four releases, ending in Studio at productive cycle34. Review sequence2.3,7.1,0.0,0.4. Game2 released at cycle24 with Scope30/30 and resolved Core half-units38/26/36/24; it legally unlocked Crown. Final cash$10,043.56, overdue$0. These are route outcomes, not Crown's incremental economic value.

The sole Crown cash offer completed two hands with Scope12 and Core half-units30/18/10/14. It earned full base completion66/66, total$1,920 including$150 upfront, plus12 base Promotion. Its Core spread was20 half-units: actual challenge grade0, bonus cash0 and bonus Promotion0. No relationship event was awarded. Shadow-grading the same outcome as the proposed Brief also yields0R, but **no Crown Brief existed or was played**.

Fresh-process replay PASS:85/85 accepted steps and exact final state, with the runner's state/RNG identity checks intact. The old [v27 route](FINDINGS-v27-current-crown-no-reuse.md) has matching high-level command/cash outcomes but different mechanics. No cross-revision state equality or current compatibility with an old checkpoint is claimed.

**Inference:** a naive strategy can earn all of Crown's base cash while missing the balanced-work promise completely. A Reputation-only Brief makes that distinction consequential. Its preview/result must explain why completing enough work is different from meeting the promise, and accessibility must be tested with a visible balance-aware policy. This one miss does not prove the candidate is too hard or that players generally fail.

## Synthetic design arithmetic

[Reproducible script](studies/crown-progression-20261024-v1/arithmetic.py) and [results](studies/crown-progression-20261024-v1/arithmetic-results.json), script SHA256 `723cead10fc66146a1e72af2ff5a8e60a71ea911ab4d4aabbbf6fbc74c945a85`.

PASS over1,252,815 constructed Scope/Core tuples: grade bounds, reversal symmetry and exact full-credit predicate. Minimum grade is never below the multiplicative alternative; it is strictly above it in665,610 tuples. Full/partial/zero counts12,606/755,558/484,651 describe this artificial grid only and **are not probabilities or player-success rates**. Promise-only assigns full grade to an empty balanced score; combined completion correctly yields0R. The named zero-Core/Scope9 example yields2.72R under minimum, so possible low-effort farming deserves a legal policy check rather than an unsupported assurance.

PASS over808 constructed commission combinations: target7.0/7.5, cap$6,000/$8,000, half/full Scope and Review0..10 by tenths. Fees remain bounded; standing requires full Scope and the target Review. This checks proposed formulas only, not canonical Crown commissions. At the recommended$8,000 cap and full Scope, Review6.0 yields$4,000 with target7.0 versus$2,000 with target7.5; partial work earns no R/I. No evidence here establishes affordability, speed or the appropriate premium.

Eight support packages conserve funding plus3,500 cents per marketing point at I15/25/40/100 for80% and60% nominal cash. At I15, SideStreet's$700/+5 compares with candidate Crown$525/+10. This is budget arithmetic, not a sales simulation or proof that five extra Awareness compensates for$175 less upfront cash.

## Commands, failures and limits

[Exact entry commands](studies/crown-progression-20261024-v1/COMMANDS.md) use `tools/simulate.py run` and `replay`; no new gameplay variant was needed for the unchanged baseline. A future Crown addition must use a named private variant.

- Initial invocation failed **before capture/import/gameplay** because a sandbox-specific TEMP directory did not persist between commands. [Failure and declared transport correction](studies/crown-progression-20261024-v1/environment-failure-v1.md), with original and replacement runtime-path records, are retained. No seed, policy, gameplay budget or target changed. A tool-orchestration syntax error also prevented one attempted retry from executing; it changed no files or cases.
- The persistent-path run and replay both exited0. Six top-level logs were scanned; each gameplay process retained a warning about six ObjectDB instances leaked at exit. [Diagnostics](studies/crown-progression-20261024-v1/runner-diagnostics.json). No additional gameplay run was used to conceal these warnings.
- New Brief accessibility, commission delivery, Crown support, migrations, UI/export and human comprehension: **NOT RUN**. Current balance and later-era scaling: **OPEN**. No new Crown implementation is claimed.

Next: after accepted P4 source is available, create a Crown Brief-only variant and predeclare legal unlock/accessibility routes before enabling commissions or support. Keep other publishers' ledgers and all approved existing payouts unchanged.
