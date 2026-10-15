class_name YinWeaponArt
extends RefCounted
const SHEET=preload("res://assets/weapons19/atlas.png")
static var data: Dictionary={}
static var icons: Dictionary={}
static func atlas() -> Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons19/atlas.json"))
	return data
static func icon(kind: String) -> AtlasTexture:
	if not icons.has(kind):
		var texture:=AtlasTexture.new()
		texture.atlas=SHEET
		texture.region=YinActorArt.rect_from(atlas()[kind].rect)
		icons[kind]=texture
	return icons[kind]
static func draw(canvas: CanvasItem,kind: String,width: float,color: Color=Color.WHITE) -> void:
	if not atlas().has(kind):return
	var entry: Dictionary=atlas()[kind]
	var source: Rect2=YinActorArt.rect_from(entry.rect)
	var size_value:=Vector2(width,source.size.y/source.size.x*width)
	var grip:=Vector2(entry.grip[0],entry.grip[1])*size_value
	canvas.draw_texture_rect_region(SHEET,Rect2(-grip,size_value),source,color)
