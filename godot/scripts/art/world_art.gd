class_name YinWorldArt
extends RefCounted
const PROPS = preload("res://assets/world22/props.png")
const DETAILS = preload("res://assets/world17/details.png")
const GROUND = preload("res://assets/world22/ground.png")
# Source regions are isolated props, normalized to existing game footprints on load.
const REGIONS = {
	"cottage": Rect2(13,6,248,247),
	"store": Rect2(278,14,250,244),
	"tree": Rect2(547,18,250,249),
	"tree_pine": Rect2(816,13,234,258),
	"tree_autumn": Rect2(1067,23,251,240),
	"rock": Rect2(1321,69,203,189),
	"grave": Rect2(33,272,208,240),
	"lantern": Rect2(304,272,138,239),
	"fence": Rect2(526,326,251,176),
	"chest": Rect2(814,335,204,172),
	"altar": Rect2(1070,278,205,236),
	"stupa": Rect2(1336,272,159,243),
	"buddha": Rect2(31,517,221,233),
	"workbench": Rect2(271,542,252,209),
	"bed": Rect2(523,557,268,175),
	"sign": Rect2(791,531,213,212),
	"reeds": Rect2(1057,523,201,228),
	"fern": Rect2(1308,515,205,236),
	"cabbage": Rect2(25,802,232,194),
	"torii": Rect2(278,751,250,248),
	"well": Rect2(545,769,233,222),
	"shrine": Rect2(778,763,220,233),
	"fallen_gate": Rect2(1038,751,276,248),
	"brazier": Rect2(1350,751,150,245)
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
	var factor: float=minf(float(size_value.x)/image.get_width(),float(size_value.y)/image.get_height())
	var fitted:=Vector2i(maxi(1,roundi(image.get_width()*factor)),maxi(1,roundi(image.get_height()*factor)))
	image.resize(fitted.x,fitted.y,Image.INTERPOLATE_NEAREST)
	var canvas:=Image.create(size_value.x,size_value.y,false,Image.FORMAT_RGBA8)
	canvas.blit_rect(image,Rect2i(Vector2i.ZERO,fitted),Vector2i((size_value.x-fitted.x)/2,size_value.y-fitted.y))
	cache[name_value] = ImageTexture.create_from_image(canvas)
	return cache[name_value]

static func surface(index: int) -> Texture2D:
	var key: String = "surface_"+str(index)
	if not cache.has(key):
		var image: Image = GROUND.get_image()
		var half: Vector2i = image.get_size()/2
		image = image.get_region(Rect2i(Vector2i(index%2,index/2)*half,half))
		image.resize(128,128,Image.INTERPOLATE_NEAREST)
		cache[key] = ImageTexture.create_from_image(image)
	return cache[key]
