class_name PublisherCatalog
extends RefCounted

const IRONCLAD := &"ironclad"
const SIDESTREET := &"sidestreet"
const CROWN_QUILL := &"crown_quill"
const NEON_CIRCUIT := &"neon_circuit"
const STARWAVE := &"starwave"

const ENTRIES := [
	{"id": IRONCLAD, "name": "Ironclad Interactive", "personality": "Conservative, dependable, production-first. Emphasizes immediate cash.", "availability": "Owns the existing cash-only Balanced Primitive Contract."},
	{"id": SIDESTREET, "name": "SideStreet Games", "personality": "A developer-friendly independent partner. Its future direction is flexible cash and promotion.", "availability": "Publisher profile only; no offer is implemented yet."},
	{"id": CROWN_QUILL, "name": "Crown & Quill Software", "personality": "A selective, quality-focused boutique. Its future direction balances cash and visibility.", "availability": "Publisher profile only; no offer is implemented yet."},
	{"id": NEON_CIRCUIT, "name": "Neon Circuit Publishing", "personality": "Loud, fashionable, and marketing-driven. Its future direction emphasizes next-release promotion.", "availability": "Publisher profile only; no offer is implemented yet."},
	{"id": STARWAVE, "name": "Starwave Entertainment", "personality": "An ambitious mass-market publisher. Larger campaigns and stricter commercial terms are future systems.", "availability": "Additional contracts are not yet available in this prototype, so this unlock cannot be completed yet."},
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
