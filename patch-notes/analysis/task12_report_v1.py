from pathlib import Path
import hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design-logs/task12-v1'
DEST=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/New Data Logs');BUNDLE=DEST/'Task12 Windows Settings v1';BUNDLE.mkdir(exist_ok=True)
gate=json.loads((OUT/'final-gate.json').read_text(encoding='utf-8'));assert gate['passed']
render=json.loads((OUT/'render.command.json').read_text(encoding='utf-8'));assert render['exit']==0 and not render['errors']
relaunch=json.loads((OUT/'relaunch-results.json').read_text(encoding='utf-8'));assert all(x['exit']==0 and not x['errors'] for x in relaunch)
before=json.loads((OUT/'source-before.json').read_text(encoding='utf-8'))
changed=[p for p,h in before['files'].items() if (ROOT/p).exists() and hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=h]
new=['scripts/settings/demo_settings_store.gd','scripts/ui/demo_settings_menu.gd','scripts/debug/verify_demo_settings.gd','data/audio_credits.json','analysis/task12_verify_v1.py','analysis/task12_relaunch_v1.gd','analysis/task12_relaunch_v1.py','analysis/task12_report_v1.py']
(OUT/'source-final-project.json').write_text(json.dumps({'files':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in changed+new}},indent=2),encoding='utf-8')
(OUT/'final-status.txt').write_bytes(subprocess.run(['git','status','--short'],cwd=ROOT,capture_output=True).stdout)
text="""PATCH NOTES — TASK12 WINDOWS SETTINGS / INPUT / AUDIO FRAMEWORK v1
STATUS: PARTIAL overall. Display, preferences, mouse/keyboard framework and audio-bus controls implemented and verified. Approved media/playback/license acceptance BLOCKED; no placeholder audio shipped.
SOURCE: main e054791d0348d90faf70e9d827892c351fa018bc (Bank), plus verified local Task33 and Task31 and preserved retained-pool/animation/Store work. Task32 was completed read-only before Task31. Task29 finance is committed at HEAD. Cached origin/main is e054791; remote-https helper unavailable prevents independent fresh remote verification. No commit/push. No AGENTS.md found in repo/ancestors; .codex-godot-temp untouched. Runtime implementations sequential, no overlapping owner found.
AUTHORITY: refreshed live Task12; cumulative §62 Windows demo/display/audio and §§68–69 finance; Task10 checkpoint specification1RhftGYA2QyldnuqfQU5vWY-6gP7158F4; current Studio Art/UI Placeholder Inventory; Task31 log/current source. No durable run save added.

IMPLEMENTED
Settings accessible from Main Menu and persistent gameplay/Studio footer. Default1280x720 window; selectable1152x648; minimum actual Windows window1152x648. No900x600 support claim. Windowed versus borderless fullscreen uses native Godot Window modes; no exclusive fullscreen. Apply a display change -> Keep/Revert with12-second real-time safety countdown. No setting is persisted until confirmed; Escape/Back/timeout restore prior committed mode/size/audio. Reset Defaults edits a draft until Apply. Failed write restores prior values and displays an error; menu actions are passive to RunState.
Preference schema1 in user://preferences-v1.cfg, separate from future user://saves/studio checkpoint. Exact typed fields validated; unsupported resolution/version/volume/types reject. Missing settings use defaults; corrupt/incomplete/unsupported files are preserved until explicit Apply. ConfigFile staged.tmp -> rename commits preferences; repeated overwrite verified on Windows. This is settings persistence, not run saving. Defaults Master/Music/SFX80%, unmuted, are adjustable presentation preferences, not economy values.
Master/Music/SFX buses created/routed to Master, independent volume gain and mute settings applied/restored. No player nodes, sound file or unapproved cues added. data/audio_credits.json records zero shipped assets and the missing approvals. Repository and design-folder search found no WAV/OGG/MP3 or approved audio/source/license package. Required remaining gate: approved music/SFX selection, cue assignments, creator/source/license/attribution, playback/mix check and actual export asset check. No claims of audible output, hearing test, licensed media or audio-complete demo.
Visible shared focus styling retained. Native Enter/Space confirm, Tab/Shift+Tab modal navigation, arrow slider adjustment and Escape Back tested using InputEventKey press/release, not just button signals. Main creation Escape returns through review/traits/setup; popup and higher-overlay focus excluded. Settings input is contained at its CanvasLayer; underlying run state is unchanged. Controller/remapping/Steam integration deferred.

EVIDENCE
GATE
Real Windows GL-compatibility render entered Window.MODE_FULLSCREEN with borderless=true, waited the actual12-second timeout, then returned to Window.MODE_WINDOWED, borderless=false, size1280x720. Explicit resolution confirmation/revert also verified. Screens at1152x648/1280x720 plus fullscreen preview were inspected. Controlled fixture sets draft mode directly, so the preview screenshot's disabled dropdown retains its earlier text; native Window state assertion records the actual fullscreen mode. Normal dropdown interaction updates its own text. This does not substitute for blocked exported interactive gameplay smoke.
Two separate Godot processes in the same isolated profile: writer saved1152x648/SFX37/Music-muted, reader loaded the exact fields and real bus mute; both exited0 without unexpected markers. Fresh profiles used for every other suite; no user's preferences or run save changed. Invalid-value/write-failure/corrupt-byte checks passed. Audio-zero/mute/unmute/defaults and passive cash/calendar/ownership/finance checks passed.
Initial focused failures: null ConfigFile fallback logged missing-key errors; explicit has_section_key guard corrected it. LineEdit consumed Escape before unhandled input; creation now routes Escape in _input only when focus belongs to that menu, leaving popups/settings alone. Both reproduced cases pass in final source. No finance or gameplay-rule changes.

FILES
FILES_LIST
Godot-generated UID companions included. Full pre/post source hashes, status/diff and exact commands/profiles/errors in patch-notes/design-logs/task12-v1; portable copy New Data Logs/Task12 Windows Settings v1.
COMMANDS: Python -B analysis/task12_verify_v1.py; same --render; Python -B analysis/task12_relaunch_v1.py. Engine4.7.1.stable.official.a13da4feb. Full argv in command JSON.
REMAINING: approved audio assets/licenses/cues/playback, human acceptance/exported interactive two-game smoke, durable run saves, open lending terms/issuance and trait effect prices, pre-existing free Alpha-exit finance guard defect. Accepted lifespan, $500 rent and all score/card/reward prices unchanged. No further code task started after this bounded pass.
"""
text=text.replace('GATE',f"Final editor import + all{len(gate['results'])-1} maintained verifiers PASS; {sum(r['assertion_passes'] for r in gate['results'])} PASS markers; zero unexpected errors, diff-check exit{gate['diff_check']}. Known root-certificate warning and declared pre-existing negative fixtures are separately classified. Render exit0; relaunch2/2 pass.").replace('FILES_LIST','\n'.join(changed+new))
log=DEST/'Patch Notes - Task12 Windows Settings Framework v1.txt';log.write_text(text,encoding='utf-8')
for f in OUT.rglob('*'):
 if f.is_file():
  d=BUNDLE/'evidence'/f.relative_to(OUT);d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,d)
for rel in changed+new:
 d=BUNDLE/'source'/rel;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,d)
print(log)
