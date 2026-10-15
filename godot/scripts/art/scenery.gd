class_name YinScenery
extends Node2D
var world: FarmWorld
var details: Array = []
var animation_clock: float = 0
func _process(delta: float) -> void:
	if world.environment == null: return
	var game := get_tree().get_first_node_in_group("yintian_game")
	if game != null and game.modal != null: return
	animation_clock += delta
	if animation_clock >= 0.12:
		animation_clock = 0
		queue_redraw()
func _ready() -> void:
	call_deferred("bake")
func bake() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = world.state.zone.hash()
	if world.state.zone in ["hall", "shop"]: return
	for i in range(int(world.level_size.x * world.level_size.y / 5500)):
		var at := Vector2(random.randi_range(24, int(world.level_size.x) - 24), random.randi_range(24, int(world.level_size.y) - 24))
		if not world.is_safe_position(at): continue
		if world.state.zone == "farm" and Rect2(304, 240, 288, 224).has_point(at): continue
		var tile: int = world.tile_farm.ground.get_cell_atlas_coords(Vector2i(at / 32)).x
		if tile >= 8 and tile != 14 and tile != 15: continue
		details.append({"at": at, "icon": 0 if random.randf() < 0.75 else 2})
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(world): return
	for detail in details: stamp(detail.at, detail.icon)
	# Contact shadows sit under the actual prop, respecting tree harvesting.
	for prop_node in world.actors.get_children():
		if not prop_node is StaticBody2D or prop_node.is_queued_for_deletion(): continue
		var width: float = 24
		for child in prop_node.get_children():
			if child is Sprite2D:
				width = minf(90, child.texture.get_width() * child.scale.x * 0.5)
		draw_set_transform(prop_node.position + Vector2(6, 0), 0, Vector2(1, 0.25))
		draw_circle(Vector2.ZERO, width, Color("142e2a55"))
		draw_set_transform(Vector2.ZERO)
	if world.state.zone == "farm":
		for y in range(40, 640, 32):
			if y >= 212 and y <= 300: continue
			stamp(Vector2(626, y), 1)
			stamp(Vector2(720, y + 8), 1)
	if world.state.zone == "village":
		for x in [260, 560, 860]:
			stamp(Vector2(x - 75, 236), 3)
			stamp(Vector2(x + 70, 230), 5)
			stamp(Vector2(x - 65, 550), 4)
			stamp(Vector2(x + 61, 542), 3)
		for garden in [Vector2(348, 480), Vector2(648, 480)]:
			draw_rect(Rect2(garden, Vector2(100, 65)), Color("35382b"))
			for row in range(3):
				for col in range(5):
					var at: Vector2 = garden + Vector2(10 + col * 18, 10 + row * 18)
					draw_texture(YinArt.texture("cabbage"), at-Vector2(8,8))
		for x in range(60, 1230, 32): stamp(Vector2(x, 108), 0)
	if world.state.zone == "island":
		for y in range(112, 1510, 32):
			if y in range(670, 855) or y in range(1190, 1336): continue
			stamp(Vector2(944, y), 1)
			stamp(Vector2(1044, y + 10), 1)
	if world.state.zone == "temple":
		for rect in [Rect2(64, 64, 1472, 32), Rect2(64, 64, 32, 1024), Rect2(64, 1216, 1472, 32), Rect2(1504, 64, 32, 1152), Rect2(96, 736, 480, 32), Rect2(736, 736, 304, 32), Rect2(1216, 736, 288, 32), Rect2(992, 96, 32, 224), Rect2(992, 448, 32, 288)]: wall(rect)
func stamp(at: Vector2, icon: int) -> void:
	if icon == 0: return # LivingGrass owns ground cover and interaction.
	if icon in [1, 3, 5, 7]:
		var name_value: String = "reeds" if icon in [1,7] else "fern"
		var image: Texture2D = YinArt.texture(name_value)
		var angle: float = sin(world.environment.time*1.6+at.y)*world.environment.wind*0.018 if world.environment != null else 0.0
		draw_set_transform(at, angle)
		draw_texture(image, Vector2(-image.get_width()*0.5,-image.get_height()+3))
		draw_set_transform(Vector2.ZERO)
		return
	draw_texture_rect_region(YinArt.SCENERY, Rect2(at-Vector2(16,28),Vector2(32,32)),Rect2(icon*32,0,32,32))

func wall(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(6, 10), rect.size), Color("172e2c77"))
	draw_texture_rect(YinWorldArt.surface(1),rect,true,Color("b8bba3"))
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color("9b9e7e"), 2)
