# 2026-11-03 startup loop video

On `main` at `529aeac8`, rendered a standalone 1280×720, 60 fps, 25.98-second MP4 at `C:\Users\64jus\Downloads\Patch Notes Design Folder\patch-notes-startup-loop.mp4`. No game source or design rules changed. Existing worktree edits were preserved.

The render uses the current JooceBox and Patch Notes source atlases, seven seconds of horizontal logo wave at the menu's 18/7-second period and 5 px scale equivalent, the existing disappearance atlas, JooceBox sound, startup/loop audio, and audio fades. It returns to black for looping. The runtime's live circuit visualization is not reproduced in this standalone render.

Check: FFmpeg decoded the output without reported errors; probe reported 25.98 s, 1280×720 at 60 fps, AAC stereo 48 kHz. Device listening and visual review remain open. The Python renderer is alongside the output in Downloads. No commit or push.

## Revision v2

Rendered `C:\Users\64jus\Downloads\Patch Notes Design Folder\patch-notes-startup-loop-v2.mp4` from the same source and script. During the disappearance atlas, the logo slides 320 output pixels over the first half and then stops while the remaining disappearance frames play. An independently drawn circuit backdrop follows the game's route geometry and responds to bass/chord/hook spectral energy sampled from the startup audio. It fades in during the one-second interval before logo reveal and fades out only after the disappearance completes. This is a standalone approximation of the runtime circuit shader, not a capture of the Godot scene. Output decodes cleanly at 25.98 s, 1280×720, 60 fps, AAC stereo 48 kHz; a mid-logo frame was visually inspected. Physical listening remains open. No game source changed, committed or pushed.

## Revision v4, full startup track

Used `C:\Users\64jus\Downloads\2026-11-03_00-32-13.mov` as a visual reference. Rendered `C:\Users\64jus\Downloads\Patch Notes Design Folder\patch-notes-startup-loop-v4.mp4` with the full 82.29-second startup/loop PCM, JooceBox opening sound and an eight-second music fade at the end. No Start or menu button appears. The logo holds after the source reveal, then slides 96 px during the first half of its disappearance. The circuit background fades only after that animation has completed and ends on JooceBox black. The 320 px slide in v3 clipped the logo; v4 corrects it. FFmpeg decoded v4 without reported errors at 1280×720, 60 fps, AAC stereo 48 kHz. A disappearance frame and final black frame were inspected. Device listening remains open. No game source or design rule changed; no commit or push.
