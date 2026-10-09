class_name PublisherCatalog
extends RefCounted

const IRONCLAD := &"ironclad"
const SIDESTREET := &"sidestreet"
const CROWN_QUILL := &"crown_quill"
const NEON_CIRCUIT := &"neon_circuit"
const STARWAVE := &"starwave"

const ENTRIES := [
	{"id": IRONCLAD, "name": "Ironclad Interactive", "personality": "Conservative, dependable, production-first. Emphasizes immediate cash.", "availability": "Owns the existing cash-only Balanced Primitive Contract."},
	{"id": SIDESTREET, "name": "SideStreet Games", "personality": "A developer-friendly independent partner.", "availability": "One $1,200 maximum cash-only offer per release meeting its size's required Scope, available after Ironclad completes. Existing offers stay available."},
	{"id": CROWN_QUILL, "name": "Crown & Quill Software", "personality": "A selective, quality-focused boutique. Rewards balanced work with cash and next-release Promotion.", "availability": "One non-expiring Contract becomes available when this publisher unlocks."},
	{"id": NEON_CIRCUIT, "name": "Neon Circuit Publishing", "personality": "Loud, fashionable, and marketing-driven. Rewards focused work with cash and next-release Promotion.", "availability": "One non-expiring Contract becomes available when this publisher unlocks."},
	{"id": STARWAVE, "name": "Starwave Entertainment", "personality": "An ambitious mass-market publisher. Larger campaigns and stricter commercial terms are future systems.", "availability": "Unlocks after two distinct releases and three distinct completed contracts. No Starwave offer is implemented yet."},
]


static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in ENTRIES:
		result.append(entry.duplicate(true))
	return result


static func name_for(id: StringName) -> String:
	for entry: Dictionary in ENTRIES:
		if entry.id == id:
			return entry.name
	return ""
