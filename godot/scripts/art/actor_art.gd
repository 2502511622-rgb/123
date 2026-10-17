class_name YinActorArt
extends RefCounted
static var animation_bands: int=8
# Reference-based source sheets remain intact. Metadata measures alpha bounds and feet.
const HERO = preload("res://assets/jrpg/hero_attack.png")
const ROSTER = preload("res://assets/monsters28/bone.png")
const TENGU = preload("res://assets/monsters28/daitengu.png")
const HERO_WALK = preload("res://assets/jrpg/hero_walk.png")
const HERO_WALK_ALT = preload("res://assets/jrpg/hero_walk_alt.png")
const HERO_ATTACK = preload("res://assets/jrpg/hero_attack.png")
const NPC = preload("res://assets/pixel30/npc.png")
const PIXEL_WALK = preload("res://assets/pixel30/hero-walk.png")
const PIXEL_WALK_ALT = preload("res://assets/pixel30/hero-alt-walk.png")
const PIXEL_COMBAT_ALT = preload("res://assets/pixel30/hero-alt-combat.png")
const PIXEL_COMBAT = preload("res://assets/pixel30/hero-combat.png")
static var pixel_data: Dictionary={}
static func pixel_pose(direction: Vector2,walk: float,moving: bool,attack: float,hurt: float,duration: float,body: int=0) -> Dictionary:
	if pixel_data.is_empty():pixel_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixel30/manifest.json"))
	var row=direction_row(direction);var combat=hurt>.08 or attack>0 or not moving
	var col=7 if hurt>.08 else YinStrikeTimeline.pose_frame(1.0-attack/maxf(duration,.01))+1 if attack>0 else 0 if combat else int(walk*16.0)%8
	var frame: Dictionary=pixel_data[("alt-" if body==1 else "")+("combat" if combat else "walk")][row][col]
	var texture=PIXEL_COMBAT_ALT if combat else PIXEL_WALK_ALT
	if body==0:texture=PIXEL_COMBAT if combat else PIXEL_WALK
	var pose=framed_pose(texture,frame,frame,float(frame.rect[3]))
	pose.rigid=true;pose.authored_frames=true
	return pose
static var npc_cache: Dictionary = {}
static var data: Dictionary = {}
static var anatomy: Dictionary = {}
static func prepare_parts() -> void:
	YinMonsterArt.metadata()
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
static func hero_pose(direction: Vector2,column: int) -> Dictionary:
	var row: int=direction_row(direction)
	if column in [1,2]:
		var frames: Array=atlas().hero_walk[row]
		return framed_pose(HERO_WALK,frames[1 if column==1 else 5],frames[0],58)
	var frames: Array=atlas().hero_attack[row]
	return framed_pose(HERO_ATTACK,frames[{0:5,3:1,4:3,5:4}.get(column,5)],frames[5],58)
static func contact_shadow(canvas: Node2D, radius: float = 10.0, phase: float = 0.0, speed: float = 0.0) -> void:
	canvas.draw_set_transform(Vector2(sin(phase)*speed*0.8,-1),0,Vector2(1.0+sin(phase*2.0)*speed*0.07,0.28-absf(sin(phase))*speed*0.035))
	for i in range(3): canvas.draw_circle(Vector2.ZERO,radius*(1.0-float(i)*0.19),Color(0.08,0.12,0.10,0.05+float(i)*0.025))
	canvas.draw_set_transform(Vector2.ZERO)
static func framed_pose(texture_value: Texture2D, frame: Dictionary, reference: Dictionary, height: float) -> Dictionary:
	var scale_value: float = height / float(reference.rect[3])
	var source: Rect2 = rect_from(frame.rect)
	var result: Dictionary={"texture": texture_value, "source": source, "destination": Rect2(-Vector2(frame.anchor[0], frame.anchor[1]) * scale_value, source.size * scale_value), "flip": bool(frame.get("mirror",false))}
	if frame.has("hand"):
		var hand: Vector2=(Vector2(frame.hand[0],frame.hand[1])-Vector2(frame.anchor[0],frame.anchor[1]))*scale_value
		if result.flip:hand.x=-hand.x
		result.hand=hand
	return result
static func hero_motion_pose(direction: Vector2, walk: float, moving: bool, attack: float, hurt: float, duration: float = 0.22, body: int = 0) -> Dictionary:
	if body in [0,1]:return pixel_pose(direction,walk,moving,attack,hurt,duration,body)
	var row: int = direction_row(direction)
	var walking: Array = atlas().hero_walk_alt if body==1 else atlas().hero_walk
	var combat: Array = atlas().hero_attack_alt if body==1 else atlas().hero_attack
	if attack > 0 or hurt > 0.08:
		var column: int = 1 if hurt>0.08 else YinStrikeTimeline.pose_frame(1.0-attack/maxf(duration,0.01))
		return framed_pose(HERO_ATTACK,combat[row][column],combat[row][5],50)
	if not moving:return framed_pose(HERO_ATTACK,combat[row][5],combat[row][5],50)
	var column: int = int(walk*16.0)%8
	return framed_pose(HERO_WALK_ALT if body==1 else HERO_WALK,walking[row][column],walking[row][0],50)

static func npc_pose(id: int, clock: float, moving: bool, talking: bool = false) -> Dictionary:
	var column: int = clampi(id-1, 0, 5)
	var row: int = 3 if talking else ([0, 1, 0, 2][int(clock*7) % 4] if moving else 0)
	if pixel_data.is_empty():pixel_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixel30/manifest.json"))
	var frame: Dictionary=pixel_data.npc[row][column]
	var pose=framed_pose(NPC,frame,frame,float(frame.rect[3]));pose.rigid=true;pose.authored_frames=true
	return pose
static func npc_texture(id: int) -> Texture2D:
	if not npc_cache.has(id):
		if pixel_data.is_empty():pixel_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixel30/manifest.json"))
		var frame: Dictionary = pixel_data.npc[0][clampi(id-1,0,5)]
		var image: Image = NPC.get_image().get_region(rect_from(frame.rect))
		image.resize(32, 48, Image.INTERPOLATE_NEAREST)
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
	if not pose.get("authored_frames",false) and pose.has("gait_phase") and float(pose.get("gait_strength",0))>0.01:
		YinFootstep.draw(canvas,pose,destination,color,offset)
		return
	var bands: int = animation_bands if not pose.get("rigid",false) and pose.texture in [HERO, HERO_WALK, HERO_WALK_ALT, HERO_ATTACK, NPC] else 1
	for band in range(bands):
		var fraction: float = float(band)/bands
		var target := Rect2(destination.position+Vector2(0,destination.size.y*fraction),Vector2(destination.size.x,destination.size.y/bands))
		var source := Rect2(pose.source.position+Vector2(0,pose.source.size.y*fraction),Vector2(pose.source.size.x,pose.source.size.y/bands))
		canvas.draw_texture_rect_region(pose.texture,target,source,color)

static func enemy_pose(kind: String, direction: Vector2, clock: float, moving: bool, attacking: bool, boss: bool) -> Dictionary:
	return {"part_key":kind,"texture":YinMonsterArt.texture(kind),"source":YinMonsterArt.region(YinMonsterArt.frame_at(clock,moving,attacking)*6),"destination":Rect2(-48,-90,96,96),"flip":direction.x<-.1,"aim":direction}

static func part_index() -> Dictionary:
	if anatomy.is_empty():
		for kind in YinMonsterArt.metadata():anatomy[kind]={}
		# Read-only identity aliases permit importing pre-v0.27 corpse snapshots.
		for row in range(4):
			for col in range(4):anatomy["daitengu:%d:%d"%[row,col]]={}
	return anatomy
static func posed_parts(kind: String, pose: Dictionary, clock: float, moving: bool, attack: bool) -> Array:
	var result: Array=[]
	var frame=YinMonsterArt.frame_at(clock,moving,attack)
	for part in YinMonsterArt.PARTS:
		var cut: Dictionary=pose.duplicate()
		cut.texture=YinMonsterArt.texture(kind)
		cut.source=YinMonsterArt.region(frame*6+YinMonsterArt.PARTS.find(part))
		cut.destination=Rect2(-48,-90,96,96)
		cut.joint=part;cut.pivot=YinMonsterArt.pivot(kind,frame,part)-Vector2(48,90)
		var phase=float(pose.get("motion",{}).get("gait",clock*10))
		var action=YinMonsterArt.attack_key(YinMonsterArt.action_for(pose.get("motion",{}),attack))
		var transform=YinMonsterArt.joint_pose(kind,part,phase,moving,action,-1,atan2(pose.get("aim",Vector2.RIGHT).y,absf(pose.get("aim",Vector2.RIGHT).x)))
		var part_scale=transform.get_scale()
		cut.destination.position=transform.origin+(cut.destination.position-cut.pivot)*part_scale
		cut.destination.size*=part_scale;cut.pivot=transform.origin
		cut.rotation=transform.get_rotation();cut.origin_texture=cut.texture;cut.origin_region=cut.source
		result.append({"part":{"arm_right":"arm","leg_right":"leg"}.get(part,part),"pose":cut})
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
