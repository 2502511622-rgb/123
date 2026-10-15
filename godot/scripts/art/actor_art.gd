class_name YinActorArt
extends RefCounted
# Reference-based source sheets remain intact. Metadata measures alpha bounds and feet.
const HERO = preload("res://assets/actors16/hero.png")
const ROSTER = preload("res://assets/jrpg/roster.png")
const TENGU = preload("res://assets/jrpg/tengu.png")
const HERO_WALK = preload("res://assets/jrpg/hero_walk.png")
const HERO_ATTACK = preload("res://assets/jrpg/hero_attack.png")
const NPC = preload("res://assets/jrpg/npc.png")
static var npc_cache: Dictionary = {}
static var data: Dictionary = {}
static var anatomy: Dictionary = {}
static var part_textures: Dictionary = {}
static func atlas() -> Dictionary:
	if data.is_empty(): data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/jrpg/atlas.json"))
	return data
static func direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y): return 2 if direction.x < 0 else 3
	return 1 if direction.y < 0 else 0
static func hero_column(walk: float, moving: bool, attack: float, hurt: float) -> int:
	if hurt > 0.08: return 5
	if attack > 0: return 3 if attack > 0.11 else 4
	return [0, 1, 0, 2][int(walk * 10) % 4] if moving else 0
static func rect_from(values: Array) -> Rect2:
	return Rect2(values[0], values[1], values[2], values[3])
static func hero_pose(direction: Vector2, column: int) -> Dictionary:
	var row: int = direction_row(direction)
	var frame: Dictionary = atlas().hero[row][column]
	var scale_value: float = 58.0 / float(atlas().hero[row][0].rect[3])
	var source: Rect2 = rect_from(frame.rect)
	return {"texture": HERO, "source": source, "destination": Rect2(-Vector2(frame.anchor[0], frame.anchor[1]) * scale_value, source.size * scale_value), "flip": row == 2 and column == 4}
static func contact_shadow(canvas: Node2D, radius: float = 10.0, phase: float = 0.0, speed: float = 0.0) -> void:
	canvas.draw_set_transform(Vector2(sin(phase)*speed*0.8,-1),0,Vector2(1.0+sin(phase*2.0)*speed*0.07,0.28-absf(sin(phase))*speed*0.035))
	for i in range(3): canvas.draw_circle(Vector2.ZERO,radius*(1.0-float(i)*0.19),Color(0.08,0.12,0.10,0.05+float(i)*0.025))
	canvas.draw_set_transform(Vector2.ZERO)
static func framed_pose(texture_value: Texture2D, frame: Dictionary, reference: Dictionary, height: float) -> Dictionary:
	var scale_value: float = height / float(reference.rect[3])
	var source: Rect2 = rect_from(frame.rect)
	return {"texture": texture_value, "source": source, "destination": Rect2(-Vector2(frame.anchor[0], frame.anchor[1]) * scale_value, source.size * scale_value), "flip": bool(frame.get("mirror",false))}
static func hero_motion_pose(direction: Vector2, walk: float, moving: bool, attack: float, hurt: float, duration: float = 0.22, body: int = 0) -> Dictionary:
	var row: int = direction_row(direction)
	var walking: Array = atlas().hero_walk_alt if body==1 else atlas().hero_walk
	var combat: Array = atlas().hero_attack_alt if body==1 else atlas().hero_attack
	if attack > 0 or hurt > 0.08:
		var column: int = 1 if hurt>0.08 else clampi(int((1.0-attack/maxf(duration,0.01))*6),0,5)
		return framed_pose(HERO_ATTACK,combat[row][column],combat[row][5],50)
	var column: int = int(walk*16.0)%8 if moving else 0
	return framed_pose(HERO_WALK,walking[row][column],walking[row][0],50)

static func npc_pose(id: int, clock: float, moving: bool, talking: bool = false) -> Dictionary:
	var column: int = clampi(id-1, 0, 5)
	var row: int = 3 if talking else ([0, 1, 0, 2][int(clock*7) % 4] if moving else 0)
	return framed_pose(NPC, atlas().npc[row][column], atlas().npc[0][column], 48)
static func npc_texture(id: int) -> Texture2D:
	if not npc_cache.has(id):
		var frame: Dictionary = atlas().npc[0][clampi(id-1,0,5)]
		var image: Image = NPC.get_image().get_region(rect_from(frame.rect))
		image.resize(32, 48, Image.INTERPOLATE_LANCZOS)
		npc_cache[id] = ImageTexture.create_from_image(image)
	return npc_cache[id]
static func draw_pose(canvas: CanvasItem, pose: Dictionary, color: Color = Color.WHITE, offset: Vector2 = Vector2.ZERO) -> void:
	var destination: Rect2 = pose.destination
	destination.position += offset
	if pose.flip:
		destination.position.x = -destination.end.x
		destination.size.x = -destination.size.x
	var rotation_value: float = float(pose.get("rotation",0))
	var pivot: Vector2 = pose.get("pivot",Vector2.ZERO)
	if pose.flip: pivot.x=-pivot.x
	if rotation_value!=0:
		var vertices := PackedVector2Array([destination.position,Vector2(destination.end.x,destination.position.y),destination.end,Vector2(destination.position.x,destination.end.y)])
		for i in range(vertices.size()): vertices[i]=pivot+(vertices[i]-pivot).rotated(rotation_value*(-1.0 if pose.flip else 1.0))
		var size_value: Vector2 = pose.texture.get_size()
		var uv: Rect2 = Rect2(pose.source.position/size_value,pose.source.size/size_value)
		canvas.draw_primitive(vertices,PackedColorArray([color,color,color,color]),PackedVector2Array([uv.position,Vector2(uv.end.x,uv.position.y),uv.end,Vector2(uv.position.x,uv.end.y)]),pose.texture)
		return
	var bands: int = 8 if pose.texture in [HERO, HERO_WALK, HERO_ATTACK, NPC] else 1
	for band in range(bands):
		var fraction: float = float(band)/bands
		var target := Rect2(destination.position+Vector2(0,destination.size.y*fraction),Vector2(destination.size.x,destination.size.y/bands))
		var source := Rect2(pose.source.position+Vector2(0,pose.source.size.y*fraction),Vector2(pose.source.size.x,pose.source.size.y/bands))
		canvas.draw_texture_rect_region(pose.texture,target,source,color)

static func enemy_pose(kind: String, direction: Vector2, clock: float, moving: bool, attacking: bool, boss: bool) -> Dictionary:
	var key: String = kind
	var frame: Dictionary = atlas().roster[kind]
	var texture_value: Texture2D = ROSTER
	var reference: Dictionary = frame
	var flip: bool = direction.x > 0.1
	if kind == "daitengu":
		var row: int = direction_row(direction)
		var column: int = 3 if attacking else ([0, 1, 0, 2][int(clock * 8) % 4] if moving else 0)
		key = "daitengu:%d:%d"%[row,column]
		frame = atlas().tengu[row][column]
		reference = atlas().tengu[row][0]
		texture_value = TENGU
		flip = false
	var scale_value: float = (70.0 if boss else 47.0) / float(reference.rect[3])
	if kind in ["chochin", "sogenbi"]: scale_value *= 0.78
	var source: Rect2 = rect_from(frame.rect)
	return {"part_key": key, "texture": texture_value, "source": source, "destination": Rect2(-Vector2(frame.anchor[0], frame.anchor[1]) * scale_value, source.size * scale_value), "flip": flip}

static func part_index() -> Dictionary:
	if anatomy.is_empty(): anatomy=JSON.parse_string(FileAccess.get_file_as_string("res://assets/jrpg/parts/parts.json"))
	return anatomy
static func posed_parts(kind: String, pose: Dictionary, clock: float, moving: bool, attack: bool) -> Array:
	var articulated: bool = moving and kind!="daitengu"
	var step: float = sin(clock*11.0) if articulated else 0.0
	var bob: float = sin(clock*2.5)*1.2 if kind in ["sogenbi","wraith","chochin"] else (-absf(sin(clock*11.0))*1.5 if articulated else sin(clock*2.0)*0.25)
	if articulated and kind=="ippon_datara":bob=-maxf(0,sin(clock*8.0))*5.0
	if articulated and kind=="jorogumo":bob=-absf(step)*0.6
	var result: Array = []
	var entry: Dictionary=part_index()[pose.part_key]
	for piece in entry.parts:
		if not part_textures.has(piece.path): part_textures[piece.path]=load(piece.path)
		var cut: Dictionary=pose.duplicate()
		var crop: Rect2=rect_from(piece.crop)
		var scale_value: Vector2=pose.destination.size/pose.source.size
		cut.origin_texture=pose.texture
		cut.origin_region=Rect2(pose.source.position+crop.position,crop.size)
		cut.texture=part_textures[piece.path]
		cut.source=Rect2(Vector2.ZERO,cut.texture.get_size())
		cut.destination=Rect2(pose.destination.position+crop.position*scale_value,crop.size*scale_value)
		cut.destination.position.y+=bob
		cut.joint=piece.joint
		var offset := Vector2(0,bob)
		var rotation_value: float=0
		if articulated and piece.joint in ["leg","leg_left"]:
			var side: float=-1.0 if piece.joint=="leg_left" else 1.0
			offset.y-=maxf(0,step*side)*3.0
			rotation_value=step*side*0.12
		if kind!="daitengu" and piece.joint in ["arm","arm_left"]:
			var side: float=1.0 if piece.joint=="arm" else -1.0
			offset.x+=side*2.0 if attack else 0.0
			rotation_value=side*(-0.14 if attack else step*0.095)
		cut.destination.position+=offset-Vector2(0,bob)
		cut.rotation=rotation_value
		cut.pivot=pose.destination.position+Vector2(piece.pivot[0],piece.pivot[1])*pose.destination.size+offset
		result.append({"part":piece.part,"pose":cut})
	return result
static func part_center(pose: Dictionary) -> Vector2:
	var center: Vector2=pose.destination.get_center()
	if pose.has("pivot"): center=pose.pivot+(center-pose.pivot).rotated(float(pose.get("rotation",0)))
	if pose.flip: center.x=-center.x
	return center
static func draw_enemy(canvas: Node2D, kind: String, pose: Dictionary, missing: Array, clock: float, moving: bool, attack: bool, color: Color) -> void:
	for piece in posed_parts(kind,pose,clock,moving,attack):
		if piece.part in missing:
			if kind!="chochin":
				var at: Vector2=piece.pose.pivot
				if piece.pose.flip:at.x=-at.x
				canvas.draw_line(at-Vector2(1.5,0),at+Vector2(1.5,0),Color("713e3c"),1.5)
			continue
		draw_pose(canvas,piece.pose,color)
