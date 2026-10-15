class_name YinWorldArt
extends RefCounted
const PROPS = preload("res://assets/world20/props.png")
const DETAILS = preload("res://assets/world17/details.png")
const GROUND = preload("res://assets/world20/ground.png")
# Source regions are isolated props, normalized to existing game footprints on load.
const REGIONS = {
	"cottage": Rect2(11,24,265,272),
	"store": Rect2(276,46,269,239),
	"tree": Rect2(547,13,282,282),
	"tree_pine": Rect2(829,17,245,278),
	"tree_autumn": Rect2(1085,34,254,261),
	"rock": Rect2(1339,140,185,156),
	"grave": Rect2(43,329,195,190),
	"lantern": Rect2(332,307,115,216),
	"fence": Rect2(527,403,248,110),
	"chest": Rect2(842,388,173,127),
	"altar": Rect2(1059,350,254,173),
	"stupa": Rect2(1358,296,144,227),
	"buddha": Rect2(28,530,213,222),
	"workbench": Rect2(284,577,236,168),
	"bed": Rect2(561,566,234,186),
	"sign": Rect2(870,543,139,200),
	"reeds": Rect2(1106,553,145,200),
	"fern": Rect2(1307,563,214,190),
	"cabbage": Rect2(22,819,209,175),
	"torii": Rect2(254,760,261,234),
	"well": Rect2(528,780,227,207),
	"shrine": Rect2(765,753,262,255),
	"fallen_gate": Rect2(1034,753,307,237),
	"brazier": Rect2(1341,753,153,251)
}
const SIZES = {
	"well": Vector2i(48,48), "shrine": Vector2i(48,64), "fallen_gate": Vector2i(96,80), "brazier": Vector2i(32,40),
	"cottage": Vector2i(160,136), "store": Vector2i(128,116),
	"tree": Vector2i(96,128), "tree_pine": Vector2i(96,128), "tree_autumn": Vector2i(96,128),
	"rock": Vector2i(40,32), "grave": Vector2i(32,48), "lantern": Vector2i(32,48),
	"fence": Vector2i(32,32), "chest": Vector2i(40,32), "altar": Vector2i(64,64), "stupa": Vector2i(48,96),
	"buddha": Vector2i(208,192), "workbench": Vector2i(80,56), "bed": Vector2i(80,52),
	"sign": Vector2i(24,42), "reeds": Vector2i(36,48), "fern": Vector2i(30,24), "cabbage": Vector2i(16,16), "torii": Vector2i(128,126)
}
static var cache: Dictionary = {}
static var source: Image
static var detail_source: Image
static func texture(name_value: String) -> Texture2D:
	if cache.has(name_value): return cache[name_value]
	if source == null: source = PROPS.get_image()
	var image: Image = source.get_region(REGIONS[name_value])
	var bounds: Rect2i = image.get_used_rect()
	image = image.get_region(bounds)
	var size_value: Vector2i = SIZES[name_value]
	image.resize(size_value.x, size_value.y, Image.INTERPOLATE_LANCZOS)
	cache[name_value] = ImageTexture.create_from_image(image)
	return cache[name_value]

static func surface(index: int) -> Texture2D:
	var key: String = "surface_"+str(index)
	if not cache.has(key):
		var image: Image = GROUND.get_image()
		var half: Vector2i = image.get_size()/2
		image = image.get_region(Rect2i(Vector2i(index%2,index/2)*half,half))
		image.resize(128,128,Image.INTERPOLATE_LANCZOS)
		cache[key] = ImageTexture.create_from_image(image)
	return cache[key]
