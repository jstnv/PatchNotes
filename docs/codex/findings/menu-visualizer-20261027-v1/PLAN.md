# Main-menu audio visualizer prototype —2026-10-27

User asks for a test audio visualizer fitting the main menu. Prior no-input authorization applies; implement one restrained option inline.

Design:24 logarithmic-frequency bars in the unused right-hand title space, cyan fill/orange peaks and restrained Theme typography/grid. Transparent decorative surface; no extra menu action or opaque panel. Keep wordmark/actions in their existing positions. Resize within the right gutter; hide when there is insufficient space rather than cover navigation. Hide/release the analyser in setup/Settings/guide and gameplay, reacquire on return.

Architecture: isolated menu_audio_visualizer.gd observes actual Music-bus FFT via a transparent AudioEffectSpectrumAnalyzer (FFT1024). Bounds/smoothing only; no fake random beats. Music/Master mute/gain and stopped transport silence the graph. Own and remove only this effect, preserving pause reverb, volume/settings and soundtrack transport. MainMenu lays out/activates the widget using its existing navigation stack. Keep compatibility for exact preceding save source; no gameplay fields/rules/RNG changes.

Plan:
1. Capture genuine current Studio/world and before source. Add failing integration checks for widget existence/layout, menu-only lifecycle and real signal/mute response.
2. Implement observer/drawing/lifecycle and integrate within existing title layout. Add only exact preceding source compatibility.
3. Native real-music frames, actual analyser/mute lifecycle tests, focused menu navigation/settings/music-grid and exact save restoration. Confirm no effect leak, input interception or signal chain mutations. No project copies/exports.
4. Independent scoped review, source audit, UI design/current/TODO and dated log. Prototype/visual/human limits explicit; no commit/push.

Docs consulted: Godot stable AudioEffectSpectrumAnalyzer (transparent pass-through; buffer/FFT configuration) and AudioEffectSpectrumAnalyzerInstance (linear stereo frequency magnitudes). Use FFT1024 for the documented latency/stability compromise, not wall-clock beat fabrication.

## Completion ledger
- [x] Genuine pre-edit Studio/world and exact original source retained; expected missing-widget red check observed.
- [x] Real FFT observer/drawing, title layout/lifecycle and exact predecessor compatibility implemented.
- [x]116 headless/119 real-WASAPI native,89 folder/29 settings/14 motion,3503 sync and10 old-world checks pass. Native frames inspected; test-helper/absent-filename failures retained.
- [x] Independent scoped review: no actionable findings. Source audit, UI design/current/TODO and dated log complete. No commit/push/export.
