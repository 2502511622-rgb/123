class_name YinActorArt
extends RefCounted
# Reference-based source sheets remain intact. Metadata measures alpha bounds and feet.
const HERO = preload("res://assets/actors16/hero.png")
const ROSTER = preload("res://assets/actors16/roster.png")
const TENGU = preload("res://assets/actors16/tengu.png")
static var data: Dictionary = {}
static func atlas() -> Dictionary:
	if data.is_empty(): data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/actors16/atlas.json"))
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
static func draw_pose(canvas: Node2D, pose: Dictionary, color: Color = Color.WHITE, offset: Vector2 = Vector2.ZERO) -> void:
	var destination: Rect2 = pose.destination
	destination.position += offset
	if pose.flip:
		destination.position.x = -destination.end.x
		destination.size.x = -destination.size.x
	canvas.draw_texture_rect_region(pose.texture, destination, pose.source, color)
static func enemy_pose(kind: String, direction: Vector2, clock: float, moving: bool, attacking: bool, boss: bool) -> Dictionary:
	var frame: Dictionary = atlas().roster[kind]
	var texture_value: Texture2D = ROSTER
	var reference: Dictionary = frame
	var flip: bool = direction.x > 0.1
	if kind == "daitengu":
		var row: int = direction_row(direction)
		var column: int = 3 if attacking else ([0, 1, 0, 2][int(clock * 8) % 4] if moving else 0)
		frame = atlas().tengu[row][column]
		reference = atlas().tengu[row][0]
		texture_value = TENGU
		flip = false
	var scale_value: float = (78.0 if boss else 51.0) / float(reference.rect[3])
	if kind in ["chochin", "sogenbi"]: scale_value *= 0.78
	var source: Rect2 = rect_from(frame.rect)
	return {"texture": texture_value, "source": source, "destination": Rect2(-Vector2(frame.anchor[0], frame.anchor[1]) * scale_value, source.size * scale_value), "flip": flip, "head_left": (0.56 if attacking else (0.30 if direction_row(direction) in [1, 3] else 0.0)) if kind == "daitengu" else 0.25, "head_right": (1.0 if attacking or direction_row(direction) in [1, 3] else 0.68) if kind == "daitengu" else 0.76}
static func pieces(kind: String, pose: Dictionary = {}) -> Array:
	# Partition the source exactly once: detached pieces and missing regions agree.
	var top: float = 0.29
	var bottom: float = 0.76
	var middle_left: float = 0.25
	var middle_right: float = 0.76
	if kind == "chochin": return [{"part": "head", "rect": Rect2(0, 0, 1, 1)}]
	if kind in ["wraith", "sogenbi"]: return [{"part": "body", "rect": Rect2(0, 0, 1, 1)}]
	var split: float = clampf(-pose.destination.position.x / pose.destination.size.x, 0.25, 0.75) if pose.has("destination") else 0.5
	var result: Array = []
	for band in range(3):
		var y: float = [0.0, top, bottom][band]
		var height_value: float = [top, bottom - top, 1.0 - bottom][band]
		if band == 2:
			result.append({"part": "body" if kind != "ippon_datara" else "leg", "rect": Rect2(0, y, split, height_value)})
			result.append({"part": "leg", "rect": Rect2(split, y, 1.0 - split, height_value)})
			continue
		var left: float = float(pose.get("head_left", middle_left)) if band == 0 else middle_left
		var right: float = float(pose.get("head_right", middle_right)) if band == 0 else middle_right
		for column in range(3):
			var x: float = [0.0, left, right][column]
			var width_value: float = [left, right - left, 1.0 - right][column]
			var part: String = "head" if band == 0 and column == 1 else ("arm" if band == 1 and column == 2 else "body")
			result.append({"part": part, "rect": Rect2(x, y, width_value, height_value)})
	return result
static func sub_pose(pose: Dictionary, region: Rect2) -> Dictionary:
	var result: Dictionary = pose.duplicate()
	result.source = Rect2(pose.source.position + region.position * pose.source.size, region.size * pose.source.size)
	result.destination = Rect2(pose.destination.position + region.position * pose.destination.size, region.size * pose.destination.size)
	return result
static func draw_enemy(canvas: Node2D, kind: String, pose: Dictionary, missing: Array, clock: float, moving: bool, attack: bool, color: Color) -> void:
	# Daitengu uses individually drawn poses; the remaining roster has articulated gaits.
	var articulated: bool = moving and kind != "daitengu"
	var step: float = sin(clock * (6.0 if "leg" in missing else 10.0)) if articulated else 0.0
	var bob: float = sin(clock * 2.5) * 1.2 if kind in ["sogenbi", "wraith", "chochin"] else 0.0
	var index: int = 0
	for piece in pieces(kind, pose):
		if piece.part in missing:
			index += 1
			continue
		var region: Rect2 = piece.rect
		var offset := Vector2(0, bob)
		if articulated and region.position.y >= 0.76:
			offset.y += maxf(0, step * (-1 if region.position.x == 0 else 1)) * -1.4
		if attack and piece.part == "arm" and kind != "daitengu": offset.x += 2.0
		draw_pose(canvas, sub_pose(pose, region), color, offset)
		index += 1
