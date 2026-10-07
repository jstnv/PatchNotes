# Disposable Fanbase replay adapter

In a writable archive copy of `bd450a9`, insert these four lines immediately after `StudioSetup/EnterStudio` is pressed in `patch-notes/analysis/task32_routes_v1.gd`. This reconciles the newer trait-confirmation UI; it does not change gameplay:

```gdscript
var backgrounds: OptionButton = menu.get_node("CenterContainer/MenuLayout/StudioTraits/Background")
backgrounds.select(1)
menu.get_node("CenterContainer/MenuLayout/StudioTraits/ReviewChoices").pressed.emit()
menu.get_node("CenterContainer/MenuLayout/CreationReview/ConfirmStudio").pressed.emit()
```

Create `patch-notes/analysis/fanbase_task32_replay_v1.gd` in that copy:

```gdscript
extends "res://analysis/task32_routes_v1.gd"

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var state := super._state_for(project, run)
	state["fans"] = run.get_fans()
	state["fan_history"] = run.get_fanbase_history()
	return state
```

Create `patch-notes/design-logs/task32-v1` as the ignored trace output directory, then run the commands in [the replay findings](2026-10-06-current-branch-replay-v1.md). Use fresh `APPDATA` and `LOCALAPPDATA` under the writable copy for Godot import and replay.
