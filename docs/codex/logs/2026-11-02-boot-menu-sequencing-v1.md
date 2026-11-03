# 2026-11-02 — track-timed boot and Main Menu

On `main` / HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`, integrated the supplied JooceBox animation, startup/alternating loops/switch tracks and Dreamwave Bass v03 menu theme with the approved Main Menu entrance. The newer request makes Start leave immediately while the logo waits for the next beat. [Source, exact checks, retained failures and limits](../findings/boot-menu-sequencing-20261102-v1/RESULT.md).

Final-source real-time native boot 8/0, real audio/loop/Studio handoff 19/0, exact converted-PCM joins 7/0 and prior paired save 4/0. The detailed native input/layout sequence passed 25/0 on the same runtime source. Maintained soundtrack, wave, loading-cover and private new-save checks passed earlier on this integration; audio/device/export and OS save-writer acceptance remain distinct. No commit/push/export; employee notifications remain queued and were not implemented.
