# Annual Game Awards — implementation v1,2026-10-31

Status: **IMPLEMENTED locally; functional/native acceptance complete. Rules and rewards ACTIVE/TRIAL; human pacing and final balance OPEN.** The user explicitly authorized best judgment to resolve every remaining rule and implement the full ceremony without input. This supersedes the earlier design/adoption gates. [Versioned implementation contract](../threads/annual-game-awards/2026-10-31-implementation-contract-v1.md) · [source, tests, retained failures and limits](../findings/annual-awards-20261031-v1/README.md).

## Categories, eligibility and ranking

| Award | Eligible candidate | Descending frozen metric |
| --- | --- | --- |
| Graphics | Games | Released Graphics Core |
| Sound | Games | Released Sound Core |
| Technology | Games | Released Technology Core |
| Design | Games | Released Design Core |
| Rising Studio | Studios | Gross earned Fans during the award year |
| Studio of the Year | Studios | Fans before this ceremony's payouts |
| Game of the Year | Games | Released Review tenths, the published one-decimal scale |

Games must actually be released in the current year by the committed cutoff. Historical prior-year titles, unreleased projects, future releases and later launches are excluded. Studio awards require at least one eligible release that year. Gross earned Fans counts actual positive monthly recruitment through cutoff, excluding founding grants and award gifts; losses do not subtract. It is not inferred from units sold.

Rank up to3 actual nominees per award. Compare exact integer metric descending, textual Studio ID ascending, then release ID ascending. Sales/units never influence GOTY or ties. Equal-score ties are explained on the leaderboard. Multiple games from one Studio and wins across categories are allowed; sparse places remain empty.

## Calendar and committed cutoff

Settle once at the productive world transaction first entering December Week2, after actual player effects, all rival commands/post-boundary launches and royalties have committed. Include all current-year releases committed by that snapshot. A separate zero-cycle player launch after that snapshot is later, even if the displayed week is still Week2. This explicit committed-event cutoff is not the whole calendar week. Later December titles do not roll into next year's awards.

Use Clock and owner calendar offsets; never assume raw45 on migrated saves. New worlds first participate in1980. An old world without awards starts with its current year only before its cutoff; at/past it, begin next year with no retroactive result or rewards. Determine this from actual calendar date/quarter, including unrepresentable Week2 cutoffs inside an old two-half prefix. Genuine prior players/worlds and modeled raw23/47 legacy cutovers are separate verified evidence.

## Once-only rewards and durable state

Each nomination entry grants10 Fans. Each win adds40 Fans and5 Awareness banked for that Studio's next successful release. Stack per entry/win across all awards; checked integer bounds are the only cap. AI/player use the same accounting. There is no cash prize, current-title retroactive Awareness or edit to past sales. Failed/canceled launches never consume the bank.

Pure rules compute rankings/reward plans first. All owners' Fan/bank plans preflight before any mutation. Chronological Fan receipts record year/cycle/counts/totals and already-committed same-cycle launches; Fan replay and Promotion provenance validate these receipts without turning them into Contract completions. The world ledger owns frozen inputs/results/rewards and presentation stages. Missing/forged current ledgers, bad inception/cutoff/offset/owners or unmatched receipts reject. Normal Continue rejects a player award receipt without its global world in synchronous, write-validation and background-read paths; detached owner hydration remains valid inside a paired restoration. Historical1977 certificate bytes/generation provenance remain untouched; the exact verified preceding ef14cc… runtime is admitted with full existing validation.

## Shared menu ceremony and controls

Use the existing FolderUI bounded surfaces, workspace Theme chamfered panels/colors, Chakra/Plex font roles/buttons and shared MenuTransitions. No second visual system. Keep Next fixed bottom-left outside scrolling content. Ten saved stages: intro, contenders overview, four Core awards, Rising Studio, Studio of the Year, GOTY, final results.

Counters animate to actual frozen values and reveal precomputed ranks; frame rate never determines ranking. Each metric has its own label/scale. Final results and overview use the same stored ranking. Use a Gameplay-owned overlay preserving the actual Studio/HUD/focus. If the cutoff happens in production, bank the result in memory and present only at safe Studio entry; do not add production Continue checkpoints.

Before showing the result and before advancing any stage, publish the paired Studio/world checkpoint. Resume exact saved stage/ranking on Continue. Double activation, failed-write Retry and teardown cannot advance twice or repay rewards. Escape/controller B cannot dismiss the ceremony; Pause/F8/hidden footer routes are gated. Normal OS quit/save remains available.

The first ceremony in each world must visit every stage even if the persistent preference is already enabled. Later ceremonies offer Skip to results. Settings and the final page expose Skip future award ceremonies; the preference skips presentation only, never accounting, and old preference files gain only the missing defaultfalse key. Final Exit returns to retained Studio with visible focus.

## Verified scope and future attention

Rules49/0, receipts60/0, component native/headless263/0; actual full Gameplay matrices56/0 each, genuine later-year auto12/0/final-resume13/0/manual18/0. Final corrected source has241/0 legal first-year checks,128/0 legal two-year checks with no injected money or loans,54/0 genuine old-save checks,35/0 modeled legacy-cutover checks and19/0 targeted native resume/Exit/focus. Thirteen selected maintained names and five focused persistence regressions pass; final exact-byte paired-world checks10/0 and native resume/Exit/focus19/0 pass. Final runtime303959a8…0b19253; see complete evidence pins. Independent final review and scoped legacy fix review have no remaining Critical/Important findings. See evidence for exact identities/overlapping coverage; counts are not summed as unique cases.

Human ceremony pacing/final reward balance, broad performance, other engines/devices and a fresh EXE/ZIP remain separate. Founder Legacy award/victory attribution/threshold activation and future roster-changing ownership integration remain separate; this feature does not enable those victory routes. The unrelated old verify_studio_checkpoint synthetic30-Scope/unconfigured-engine fixture still fails in both the exact pre-awards archive and current project; it is retained for separate fixture maintenance.
