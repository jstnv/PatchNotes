class_name CardData
extends RefCounted

const PHASE_DESIGN: StringName = &"design"
const PHASE_ALPHA: StringName = &"alpha"
const PHASE_BETA: StringName = &"beta"
const PHASE_STUDIO: StringName = &"studio"

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

var artwork_path: String


static func is_valid_phase(value: StringName) -> bool:
	return value in [PHASE_DESIGN, PHASE_ALPHA, PHASE_BETA, PHASE_STUDIO]
