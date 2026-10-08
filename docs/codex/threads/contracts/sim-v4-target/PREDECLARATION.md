# Contracts target sensitivity v4 — predeclaration

2026-10-07 (America/Los_Angeles). Read-only analysis. Source is the pinned Task 34 isolated main `b84d1a5b4e4957b044b4b52c41553cf611aff3ae` project and its typed, legally reached checkpoints. Candidate offers and payout are analysis overlays; Crown and Neon offers and Promotion are not live gameplay.

## Inputs fixed before outcomes

Use the earliest native eligible release from exactly four existing Task 34 typed routes:

| Publisher | Startup | Input checkpoint | SHA-256 |
|---|---|---|---|
| Crown | legacy $5,500 | `../sim-v3/route-legacy-ordinary-0-0.bin` | `83E8DF43CB78F9913B634C67C55C71CFD697A3EA80E8AF4B989B6556644C776C` |
| Crown | current $5,700 | `../sim-v3/route-trait-ordinary-0-0.bin` | `0AF2DED18F1F787FEFC7EC2A0472A58DCD1C516FB2ADDF2ACC8A76E7194EC057` |
| Neon | legacy $5,500 | `../sim-v3/route-legacy-ordinary-0-1.bin` | `5C19295B148C3AEF24377423D36F24D24F06D4C0849EC94630D76C12FF415A33` |
| Neon | current $5,700 | `../sim-v3/route-trait-ordinary-0-1.bin` | `486E0F9584B862E56F4C6C382B87B904F9E9083E1C03D9229DB98372110EB431` |

Task 34 source manifest SHA-256 is `2D13075A1093810B4E254294FCF3557E921A2866B98436FDD1010957798842E2`; native analysis base `advance.gd` SHA-256 is `E6E163D5D9EF42D393B5563FEBDB8C9006785AC43954917993A3F254AA010970`. Copy only the needed pinned project files to `project/` here, with isolated Godot profiles here. Do not modify the prior Task 34 experiment, shared source or gameplay.

## Bounded comparison

- For each of the four checkpoint files, use draw seeds `200929000`, `200929001`, `200929002`, acceptance advance $0, candidate caps Crown $1,920 and Neon $1,560, and candidate Promotion caps 12/20. Compare Crown Scope targets 9 versus 10 and Neon 10 versus 11. This is 24 candidate arms if all remain eligible and runnable.
- Freeze current owned Primitive features from the typed checkpoint. Use native Contract card draw, seven-card display, the existing single same-class redraw, four-card `ContractState.plan_hand` validation, finite Feature exhaustion, retained cards, normal refill, and exactly two successful productive hands when finance permits.
- The target-independent **low-Scope stress policy** enumerates legal four-card combinations in ascending slot order. It keeps combinations with positive `plan.scope_addition` and positive total Core half-score addition. Choose minimum Scope addition; break ties by maximum total Core half-score addition; break remaining ties by the first enumerated combination. Reapply at the second hand. This intentionally tests lower Scope while retaining Core work; it is not an estimated player strategy.
- Compare the two targets on identical draw/selection/hand traces. Separately floor exact-cent completion cash and whole Promotion using the fixed-share candidate formulas. The cash receipt uses the validated native finance planner only after the committed second hand; Promotion is reported conditionally and is not injected into sales. Do not vary caps or use these runs to approve caps.
- Independently audit input hashes, native eligibility, selected-card legality, two successful hands or explicit rejection, target-paired trace identity, Scope/Core totals, rational formula and floor, harder-target monotonicity, ledger receipt once, cash/arrears and cycle. Report every arm, including failures or censored cases. If all completed hands reach the harder Scope target, report this as a nondiscriminating sensitivity rather than changing the route or policy after seeing results.

These four routes and three seeds are a deliberate boundary stress, not a population or economic balance sample. The result may show formula sensitivity without demonstrating that low-Scope play is attractive or likely. No numerical target, cap, advance or Promotion approval follows from this experiment.
