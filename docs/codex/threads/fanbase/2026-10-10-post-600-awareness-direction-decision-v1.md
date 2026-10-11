# Post-600 Fan Awareness direction — decision v1

2026-10-10, America/Los_Angeles. In response to the [600-Fan plateau question](2026-10-10-post-600-awareness-question-v1.md), the user selected **“Keep improving, with diminishing returns.”**

## Ruling

**LOCKED design direction for later tuning:** Within the intended later playable range, Fan counts beyond600 should continue improving future launches' fan-derived Awareness, with smaller marginal benefits as the audience grows. A hard stop at600 Fans is not the desired final direction. Keep the existing frozen-at-launch snapshot and one Awareness-to-sales conversion. Integer rounding may create short intervals with no displayed Awareness change; no exact per-Fan increase is implied by this conceptual ruling.

**ACTIVE/TRIAL runtime remains unchanged:** The current `min(150, floor(Fans/4))` mapping still caps at600 Fans. The user did not select a replacement curve, numeric rate, endpoint, final cap or implementation timing. Those remain **OPEN**. The previously reported 367-Fan/91-Awareness launch felt right below the cap; preserve that evidence without treating it as a test of any post-600 candidate. No gameplay or shared TODO edit is authorized by this design direction alone.
