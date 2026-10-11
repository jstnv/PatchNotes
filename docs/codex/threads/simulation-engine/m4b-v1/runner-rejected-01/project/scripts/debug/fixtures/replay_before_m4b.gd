## TEST ORACLE: pre-M4b projection, derived by m4b-v1/make_oracle.py.
## Versioned deterministic action tapes, supplied with an identical initialized
## DevelopmentSession. No save migration, Studio restore or AI policy is implied.
extends RefCounted

const SCHEMA_VERSION := 1

static func freeze(value: Variant) -> Variant:
	if value is int: return {"integer":str(value)}
	if value is float: return {"float_bits":var_to_bytes(value).hex_encode()}
	if value is StringName: return str(value)
	if value is RandomNumberGenerator: return {"seed":str(value.seed),"state":str(value.state)}
	if value is CardData: return str(value.id)
	if value is Array: return value.map(func(item: Variant) -> Variant: return freeze(item))
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[str(key)]=freeze(value[key])
		return result
	if value is Object:
		var result: Dictionary = {}
		for property in value.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: result[property.name]=freeze(value.get(property.name))
		return result
	return value

static func state(session: RefCounted) -> Dictionary:
	if session.has_method("replay_state"): return _campaign_state(session)
	var definitions: Array = []
	for card: CardData in session.catalog.cards.values():
		var fields: Dictionary = {}
		for property in card.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: fields[property.name]=freeze(card.get(property.name))
		definitions.append(fields)
	return {"project":freeze(session.project),"run":freeze(session.run),"hand":freeze(session.hand),"phase":session.phase_index,"sequence":session.sequence,"confirmation":session.awaiting_confirmation,"finalized":session.finalized,"definitions":definitions,"snapshots":freeze(session.snapshots)}

static func digest(value: Variant) -> String:
	return JSON.stringify(freeze(value)).sha256_text()

static func _campaign_state(session: RefCounted) -> Dictionary:
	var definitions: Array = []
	for card: CardData in session.catalog.cards.values():
		var fields: Dictionary = {}
		for property in card.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: fields[property.name] = freeze(card.get(property.name))
		definitions.append(fields)
	# Completed presentation objects are not Studio authority. Continue has always
	# discarded them; canonical Studio replay state must do the same.
	return {"kind":"campaign_v2","run":freeze(session.run),"sequence":session.sequence,"studio":session.in_studio,"development":{} if session.development == null or session.in_studio or session.contract != null else state(session.development),"contract":{} if session.contract == null or session.in_studio else freeze(session.contract),"definitions":definitions,"snapshots":freeze(session.snapshots)}

