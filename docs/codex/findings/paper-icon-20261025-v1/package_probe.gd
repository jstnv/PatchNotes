extends SceneTree
const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	for path: String in manifest.files:
		assert(FileAccess.get_sha256(path) == manifest.files[path].sha256, "Embedded payload mismatch: "+path)
	assert(ProjectSettings.get_setting("application/config/name") == "Patch Notes", "Preserve the existing save folder")
	assert(ProjectSettings.get_setting("application/config/version") == "0.02", "Build version")
	assert(ProjectSettings.get_setting("application/config/icon") == "res://assets/branding/patch_notes_paper.png")
	assert(ProjectSettings.get_setting("application/config/windows_native_icon") == "res://assets/branding/patch_notes_paper.ico")
	assert(FileAccess.file_exists("res://assets/branding/patch_notes_paper.ico"), "Native ICO ships as raw data")
	var texture := load("res://assets/branding/patch_notes_paper.png") as Texture2D
	assert(texture != null and texture.get_width()==1254 and texture.get_height()==1254)
	var image := texture.get_image()
	assert(image.get_pixel(0,0).a == 0.0 and image.get_pixel(1253,1253).a == 0.0, "Transparent icon corners")
	# Imported PNGs ship as remapped texture resources; original input bytes are
	# independently pinned in the build manifest, rather than read as raw PCK files.
	var wordmark := load("res://assets/branding/patch_notes_logo.png") as Texture2D
	assert(wordmark != null and wordmark.get_width()==1254 and wordmark.get_height()==1254, "Full wordmark remains available")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	var codec := Codec.new()
	var player: RunState = StudioCheckpoint.new().hydrate(data.player)
	var world := codec.restore(data.world,data.player,player,root.get_node("CardDatabase").get_development_catalog())
	assert(world != null, codec.error)
	var captured := codec.capture(world)
	var expected: Dictionary = data.world.duplicate(true)
	captured.erase("source_identity"); expected.erase("source_identity")
	assert(captured == expected and StudioCheckpoint.new().capture(player) == data.player, "Current editor save must stay exact")
	var invalid: Dictionary = data.world.duplicate(true)
	invalid.source_identity = "0".repeat(64)
	assert(not codec.validate(invalid,data.player).is_empty(), "Unknown sources still reject")
	FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"payloads":manifest.files.size(),"current_editor_save_exact":true,"unknown_source_rejected":true,"paper_icon":true,"wordmark_unchanged":true,"runtime_identity":Replay.source_identity()}))
	print("EMBEDDED_PACKAGE_PASS ",manifest.files.size()," payloads; paper icon; exact current-editor save/RNG")
	quit()
