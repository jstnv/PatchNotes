# Player 10.0 Review recovery — bounded review v1

2026-10-10, America/Los_Angeles. **USER-REPORTED REVIEW AND PLAYER FEEL; VISIBLE STUDIO JOURNAL; no numerical ruling.** This follows the same no-Cult run's [0.4 Review loss capture](2026-10-10-weak-release-player-feel-v1.md). The user reports making a **10/10** game, shared the [Studio Fans screenshot](captures/2026-10-10-player-10-review-recovery-v1.png), and answered **“About right”** when asked how recovery felt. The image's SHA-256 is `367F921780CF21691E4F04B537B1B60F3F219D22EC31A76EB632FBD98E39169C`. No build hash, per-title Fan journal, launch Review detail, frozen Fans, Fan Awareness, sales or checkpoint accompanies it. Shared checkout inspected: `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, with concurrent uncommitted work.

## Visible arithmetic

The screenshot shows Current Fans **597**. Months62–71 move **358→367**: gains `2+2+1+1+1+1+0+0+0+1=9`, zero displayed loss. Month72 is `367+71−0=438`; month73 is `438+159−0=597`. Thus the two visible surge months add **230 net Fans**, and all twelve shown months add **239**. The prior screenshot ended month57 at **338**; months58–61 are not shown here, so their net **+20** is implied by month62's 358 starting total but cannot be broken down. The full observed endpoints are **338→597, +259** with that visibility gap.

The screenshot is a **studio aggregate**. The reported 10.0 title plausibly drives the large month72–73 gains, but the displayed rows cannot assign all230 gains to it because older concurrent titles may also gain Fans. Nor can they isolate the title's sales or verify that its launch Fan Awareness contributed to sales once. The image directly supports a strong recovery in the studio total, not a per-title conversion-rate estimate.

## Design disposition

The player considers this recovery **about right**. Together with their earlier “About right” reaction to 550→867 growth and “feels right” reaction to the 0.4 Review loss, this is qualitative support for **continuing the current playable trial without a tuning change**. Keep the 8% gain scale, 15% loss scale and quarter-Fan Awareness mapping **ACTIVE/TRIAL**; none is final-locked by these screenshots. The 5.0-neutral and incremental/shared-cap/zero-minimum rules retain their existing **LOCKED** status. Cross-title attribution, launch Awareness effect, longer compounding and Review4.8–4.9 feel remain **OPEN**.

If the player has an easy capture available, the smallest addition is this 10.0 title's immutable Review detail showing frozen launch Fans and Fan Awareness, alongside its first two monthly sales rows. That would answer the launch-benefit question without replaying the run. No new implementation handoff or shared TODO entry follows from this feedback alone.
