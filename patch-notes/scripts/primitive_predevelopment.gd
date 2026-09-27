class_name PrimitivePredevelopment
extends RefCounted

const PATH := "res://data/primitive_predevelopment.json"
const REQUIRED_SCOPE := 30

static func catalog() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

static func find_entry(kind: String, id: StringName) -> Dictionary:
	for entry: Dictionary in catalog().get(kind, []):
		if StringName(entry.id) == id:
			return entry
	return {}

static func validation_error(base_name: String, genre: StringName, theme: StringName) -> String:
	if base_name.strip_edges().is_empty():
		return "Enter a game name."
	if find_entry("genres", genre).is_empty():
		return "Choose a Primitive genre."
	if find_entry("themes", theme).is_empty():
		return "Choose a Primitive theme."
	return ""

## Pure preparation. Confirmation commits time through RunState only after the
## project, market snapshots and destination scene have all been prepared.
static func prepare_project(base_name: String, genre: StringName, theme: StringName, run: RunState) -> ProjectState:
	if run == null or not validation_error(base_name, genre, theme).is_empty():
		return null
	var project := ProjectState.new(REQUIRED_SCOPE)
	if not project.configure_predevelopment(base_name, genre, theme, run.get_owned_feature_ids()):
		return null
	return project
