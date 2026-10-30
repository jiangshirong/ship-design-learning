extends RefCounted
static var cache: Dictionary = {}
const GRADE_ICONS = ["trophy", "circle-check", "sprout", "circle-help"]
const GRADE_COLORS = ["1f514a", "558575", "ac7a32", "a45c55"]

static func texture(name: String) -> Texture2D:
	if cache.has(name): return cache[name]
	# ResourceLoader follows SVG import remaps in release APKs; the raw SVG
	# is only available in the source project. White artwork is tinted by UI.
	var result: Texture2D = load("res://modules/review/mobile_ui/assets/icons/" + name + ".svg")
	cache[name] = result
	return result
