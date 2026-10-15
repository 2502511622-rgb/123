class_name YinWorldArt
extends RefCounted
const PROPS = preload("res://assets/world17/props.png")
const DETAILS = preload("res://assets/world17/details.png")
const GROUND = preload("res://assets/world17/ground.png")
# Source regions are isolated props, normalized to existing game footprints on load.
const REGIONS = {
	"cottage": Rect2(0, 75, 420, 388), "store": Rect2(420, 94, 248, 369),
	"tree": Rect2(668, 52, 350, 467), "tree_pine": Rect2(1018, 40, 236, 479),
	"tree_autumn": Rect2(0, 480, 384, 423), "rock": Rect2(384, 565, 321, 338),
	"grave": Rect2(705, 532, 310, 373), "lantern": Rect2(1015, 520, 239, 360),
	"fence": Rect2(0, 960, 380, 268), "chest": Rect2(380, 960, 296, 268),
	"altar": Rect2(676, 920, 342, 318), "stupa": Rect2(1018, 886, 236, 368),
	"buddha": Rect2(0,0,440,610), "workbench": Rect2(440,170,460,440), "bed": Rect2(910,170,340,440),
	"sign": Rect2(1250,50,286,560), "reeds": Rect2(0,620,410,404), "fern": Rect2(410,620,400,404),
	"cabbage": Rect2(810,700,310,324), "torii": Rect2(1120,610,416,414)
}
const SIZES = {
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
	if detail_source == null: detail_source = DETAILS.get_image()
	var extra: bool = name_value in ["buddha", "workbench", "bed", "sign", "reeds", "fern", "cabbage", "torii"]
	var image: Image = (detail_source if extra else source).get_region(REGIONS[name_value])
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
