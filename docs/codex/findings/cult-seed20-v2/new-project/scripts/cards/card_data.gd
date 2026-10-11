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


static func is_valid_phase(value: StringName) -> bool:
	return value in [PHASE_DESIGN, PHASE_ALPHA, PHASE_BETA, PHASE_STUDIO]


static func is_valid_beta_category(value: StringName) -> bool:
	return value in [BETA_CATEGORY_QA, BETA_CATEGORY_MARKETING, BETA_CATEGORY_INSIDER]


static func is_valid_qa_operation(value: StringName) -> bool:
	return value in [QA_OPERATION_SEARCH, QA_OPERATION_DEBUG]
