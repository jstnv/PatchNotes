# Logo-only startup movie variation, 2026-11-05

Created a separate variation of the [28-second movie with a 19-second thread cutoff](2026-11-05-startup-video-stop19-28s.md). The user requested the logo without the playtest announcement. Removed both announcement text and its surrounding panel throughout its entrance, hold and return; retained the JooceBox intro, Patch Notes logo, reactive field, soundtrack and closing sequence.

Inspected branch `main`, HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`, status and diff. Preserved all 77 tracked modifications and pre-existing untracked evidence. This session adds only this repository log. The media workspace contains the renderer and verification receipts under `dream-logo-only/`.

Reconstructed frames 853-1212 from the existing lossless circuit plates and clean completed logo artwork, without the announcement layer. The cutoff plate begins at global 1080 and retains the prior 19-second cutoff. Copied all 1,320 frames outside the reconstructed window and every AAC packet from the previous movie. Earlier video versions remain available.

`dream-logo-only/verify_logo_only.py` PASS: all streams fully decode; exact 28-second audio/video clocks; 1,680 1920x1080 frames at 60 fps with 800-tick packet spacing; stereo AAC at 48 kHz; all audio packets and timestamps unchanged; all 1,320 untouched decoded frames pixel-identical; first frame and final 12 frames pure black. Representative visual review shows the logo and circuitry without announcement text or panel.

Published `C:\Users\64jus\Downloads\Patch Notes Design Folder\Patch-Notes-Startup-Loop-Logo-Only-28s.mp4`, 10,391,109 bytes, SHA-256 `e50b2aa4f583e9d4db1130419a38fa6ef6ba64043e9e93821e816219c861cc2f`. Destination hash matches the verified export. Scratch root: `C:\Users\64jus\.codex\visualizations\2026\11\03\01a1a0c8-3f8f-7370-8517-b062c085838f`. No game source changes, commit or push.

Independent decoded-picture QA passed 8/8 checks. Across all 360 edited frames, the former announcement region matches the clean native field and contains no purple panel pixels. Main logo cream-pixel recall is 99.997%; neither splice introduces a flash. Report and contact sheet: `existing-audit/logo-only/logo-only-report.json` and `logo-only-decoded-review.jpg`.
