# Share sales and loss of control — user ruling v1

**Date:** 2026-10-11 (America/Los_Angeles). **Status:** LOCKED direction where stated below; two interpretation questions remain OPEN. **Scope:** design record only.

## User direction

> Losing control should be based on stocks sold. Selling stocks is voluntary unless a competitor gives you an offer based on your valuation.

## Transaction rule

- Loss of control is calculated from the committed cap table. A competitor's interest, valuation, offer, warning or negotiation does not itself move votes. A completed, valid equity transaction must change the holdings before the control state changes.
- A competitor-initiated offer must identify the target Studio, seller, number of equal shares, current valuation basis, actual price, expiry and resulting ownership fraction. The valuation gives a price anchor; a premium or negotiated price is disclosed. No offer can silently transfer the Studio's cash, debt, employees or IP.
- If a founder sells, only the specified shares leave the founder's holding. Compare the resulting direct holder units with issued units using the existing strictly-greater-than-50% rule. Selling a minority block may reduce founder ownership without granting the competitor control. Exact 50% leaves no majority controller.
- Secondary-sale proceeds follow the selected no-personal-wallet settlement rule in [SPEC-v2](SPEC-v2.md); the target Studio receives no cash from a secondary sale. An offer is never a free new-Studio funding source.

## Clarifications in progress

1. **Founder consent to a competitor offer:** Does the phrase “unless a competitor gives you an offer” mean the player may accept or decline an unsolicited valuation-based bid, or can a bid compel sale of founder shares? [SPEC-v2](SPEC-v2.md) currently requires explicit founder acceptance. Preserve that rule until the user clarifies; do not implement compelled sales from this sentence alone.
2. **Which holders can cause control loss:** Does “stocks sold” include shares sold by passive/corporate holders, which can give a competitor majority without founder sale? [SPEC-v2](SPEC-v2.md) currently allows willing holders to sell. The treatment of separately authorized primary issuance and dilution also remains as documented there until clarified.

The user was asked both questions in this thread. Once answered, publish a superseding ruling and reconcile the takeover/transition sections of the selected specification and handoff. No simulator, gameplay, shared TODO or other thread documents change from this record.
