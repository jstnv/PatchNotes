class_name CardData
extends RefCounted

const PHASE_DESIGN: StringName = &"design"
const PHASE_ALPHA: StringName = &"alpha"
const PHASE_BETA: StringName = &"beta"
const PHASE_STUDIO: StringName = &"studio"

const BETA_CATEGORY_QA: StringName = &"qa"
const BETA_CATEGORY_MARKETING: StringName = &"marketing"
const BETA_CATEGORY_INSIDER: StringName = &"insider"

const QA_OPERATION_SEARCH: StringName = &"search"
const QA_OPERATION_DEBUG: StringName = &"debug"

var id: StringName
var card_name: String
var card_type: StringName
var phase: StringName
var department: StringName

var primary_stat: StringName
var primary_value: int

var secondary_stat: StringName
var secondary_value: int

var scope: int
var renewable: bool

var beta_category: StringName
var beta_value: int
var qa_operation: StringName

var artwork_path: String

# Only explicitly ordered definitions use this storage. Legacy fixtures retain
# their existing fields and validation semantics.
var _ordered_core_contributions: Array = []
const CORE_STATS := [&"graphics", &"sound", &"technology", &"design"]
# Exact integer quotient of the signed 64-bit maximum divided by 1200.
const MAX_ORDERED_VALUE: int = 7686143364045646

static func ordered_contributions_error(value: Variant) -> String:
	if not value is Array or value.size() < 1 or value.size() > 3:
		return "Expected one to three ordered Core contributions"
	var seen := {}
	for entry: Variant in value:
		if not entry is Dictionary or entry.size() != 2 or not entry.has("stat") or not entry.has("value"):
			return "Each Core contribution requires stat and value"
		if typeof(entry.stat) not in [TYPE_STRING, TYPE_STRING_NAME] or StringName(entry.stat) not in CORE_STATS or seen.has(StringName(entry.stat)):
			return "Core categories must be known and distinct"
		var amount: Variant = entry.value
		if typeof(amount) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(amount)) or amount <= 0 or amount > MAX_ORDERED_VALUE or amount != floor(amount):
			return "Core values must be positive bounded integers"
		seen[StringName(entry.stat)] = true
	return ""

func set_core_contributions(entries: Array) -> bool:
	if not ordered_contributions_error(entries).is_empty() or phase not in [PHASE_DESIGN, PHASE_ALPHA]: return false
	_ordered_core_contributions = []
	for entry: Dictionary in entries:
		_ordered_core_contributions.append({"stat":StringName(entry.stat), "value":int(entry.value)})
	primary_stat = _ordered_core_contributions[0].stat
	primary_value = _ordered_core_contributions[0].value
	secondary_stat = _ordered_core_contributions[1].stat if entries.size() > 1 else &""
	secondary_value = _ordered_core_contributions[1].value if entries.size() > 1 else 0
	return true

func core_contributions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _ordered_core_contributions.is_empty():
		result.assign(_ordered_core_contributions.duplicate(true))
	elif not primary_stat.is_empty():
		result.append({"stat":primary_stat,"value":primary_value})
		if not secondary_stat.is_empty(): result.append({"stat":secondary_stat,"value":secondary_value})
	return result

func ordered_runtime_error() -> String:
	if _ordered_core_contributions.is_empty(): return ""
	var reason := ordered_contributions_error(_ordered_core_contributions)
	if not reason.is_empty(): return reason
	var entries := _ordered_core_contributions
	if phase not in [PHASE_DESIGN, PHASE_ALPHA] or primary_stat != entries[0].stat or primary_value != entries[0].value:
		return "Ordered primary projection is inconsistent"
	if secondary_stat != (entries[1].stat if entries.size() > 1 else &"") or secondary_value != (entries[1].value if entries.size() > 1 else 0):
		return "Ordered secondary projection is inconsistent"
	return ""

func printed_core_total() -> int:
	var total := 0
	for entry in core_contributions(): total += int(entry.value)
	return total


static func is_valid_phase(value: StringName) -> bool:
	return value in [PHASE_DESIGN, PHASE_ALPHA, PHASE_BETA, PHASE_STUDIO]


static func is_valid_beta_category(value: StringName) -> bool:
	return value in [BETA_CATEGORY_QA, BETA_CATEGORY_MARKETING, BETA_CATEGORY_INSIDER]


static func is_valid_qa_operation(value: StringName) -> bool:
	return value in [QA_OPERATION_SEARCH, QA_OPERATION_DEBUG]
