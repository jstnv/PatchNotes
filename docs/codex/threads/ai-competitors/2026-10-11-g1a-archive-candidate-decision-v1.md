# 2026-10-11 G1a incumbent archive candidate decision v1

**Status: CANDIDATE FOR DESIGN REVIEW.** The 2026-10-09 [frozen-history decision](2026-10-09-incumbent-history-decision-v1.md) is LOCKED. This record selects a private prototype representation and evidence packet; it does **not** approve an incumbent cohort, numerical advantage, save migration, UI or canonical gameplay change.

## Recommended representation

Store pre-1980 titles in a typed, frozen `historical_titles` array separate from ordinary `released_games` and `release_metadata`. Each record has stable ID, title, Genre, Theme, year below 1980 and Review tenths. An explicit January 1980 `opening_snapshot` records studio ID, starting cash/Fans, completed owned Features, empty Research/familiarity provenance and archive count. The first post-start title enters the ordinary live release ledger only after accepted legal Design, Alpha, Beta and launch commands. Archive titles never create post-start sales, Fans, Store payments, release age or news.

The private v2 bootstrap accepts historically completed, known, prerequisite-consistent owned Features. It obtains cash and Fans from legal starting traits, not direct score/resource grants. Its Action fixture uses Family Funding and Cult Following, adds `music`, `dialogue`, `secrets`, and uses placeholder 1977/1979 titles. These exact inputs, including $5,850 and **20** starting Fans under the current Cult trial, are **OPEN examples**. The plan's 40-Fan expectation was wrong; the baseline measured 20.

## Alternatives logged

- Put old titles in `released_games`: rejected for this prototype because current checkpoint validation ties live titles to nonnegative run cycles, settlement and Fanbase history. It would fabricate post-start accounting.
- Keep a sidecar archive outside Studio state: deferred because the tested Studio Continue would not itself prove historical state persistence.
- Model old sales and Fan accrual after January 1980: conflicts with the LOCKED frozen archive.

## Prototype and acceptance boundary

The [v2 private simulator](simulators/g1a-incumbent-archive-v2/) is the source-pinned review candidate. Its [finding](2026-10-11-g1a-archive-finding-v1.md) covers two fresh legal opening releases, negative bootstrap cases, one Studio continuation and exact fresh-process replays. A v3 [migration probe](simulators/g1a-incumbent-archive-v3/) added prior-schema decode defaults, but the simulator correctly rejects cross-revision Studio envelopes at its independent source-identity fence. v3 is exploratory, **not** an approved replacement or a proven save migration.

Before canonical adoption, review an actual incumbent roster/count, cash/Fans, traits, owned Features, past titles/Reviews and any familiarity provenance; specify how existing player saves and source-pinned simulation envelopes migrate without weakening identity/integrity checks; expose the archive in the intended UI; then verify shared-world persistence and legal opening releases. The finite fixture policy is an experiment driver, not approved rival AI. G2 shopping, G4 policies/entrants, G5 news/CPU and market influence on Reviews remain separate.
