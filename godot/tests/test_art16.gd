extends SceneTree
var checks: int = 0
var failures: int = 0
var game: Node2D
func check(ok: bool, text: String) -> void:
	checks += 1
	print("ART16 ", "PASS " if ok else "FAIL ", text)
	if not ok: failures += 1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT", "1")
	call_deferred("run")
func frames(count: int = 4) -> void:
	for i in range(count): await physics_frame
func capture(name_value: String) -> void:
	if is_instance_valid(game):
		game.player.get_node("Camera2D").reset_smoothing()
		game.player.get_node("Camera2D").force_update_scroll()
	await frames()
	if DisplayServer.get_name() == "headless" or OS.get_environment("YINTIAN_CAPTURE_DIR") == "": return
	await RenderingServer.frame_post_draw
	var folder: String = OS.get_environment("YINTIAN_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name_value + ".png")) == OK, "capture " + name_value)
func run() -> void:
	var title = load("res://scenes/ui/title_screen.tscn").instantiate()
	root.add_child(title)
	await frames()
	await capture("art16-title")
	title.queue_free()
	await frames()
	check(YinBalance.MONSTERS.keys().all(func(kind): return YinActorArt.atlas().roster.has(kind)), "reference atlas covers all 23 enemy types")
	check(YinActorArt.atlas().hero.size() == 4 and YinArt.VILLAGERS.get_size() == Vector2(192, 44), "four-direction hero and six resident portraits remain available")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.close_modal()
	game.state.intro_seen = true
	game.state.factions.last_day = game.state.day
	game.state.minutes = 1020
	game.player.position = Vector2(416, 272)
	await capture("art16-farm")
	check(game.world.tile_farm.ground.scale == Vector2.ONE and game.world.tile_farm.crops.scale == Vector2(2, 2), "higher density terrain retains existing crop coordinate scale")
	check(game.world.plot_center(0) == Vector2(336, 272) and game.world.plot_at(Vector2(336, 272)) == 0, "art changes preserve farming interaction coordinates")
	check(game.world.tile_farm.ground.get_used_cells().any(func(cell): return game.world.tile_farm.ground.get_cell_atlas_coords(cell).x >= 16), "stone roads use connected edge atlas")
	check(game.world.actors.get_children().any(func(node): return node is StaticBody2D and node.get_children().any(func(c): return c is Sprite2D and c.texture == YinArt.texture("cottage") and c.scale == Vector2.ONE)), "new cottages use native-density assets at unchanged footprints")
	game.state.minutes = 1260
	game.travel("village")
	game.player.position = Vector2(540, 256)
	await capture("art16-village-night")
	check(get_nodes_in_group("art_lights").any(func(n): return game.world.is_ancestor_of(n)), "village paper lanterns register world-bound lights")
	check(game.atmosphere.lighting.get_shader_parameter("light_count") > 0 and game.atmosphere.lighting.get_shader_parameter("night") > 0.9, "visible lamps and nighttime reach actual lighting shader")
	game.state.minutes = 600
	await capture("art16-village-day")
	check(game.atmosphere.lighting.get_shader_parameter("night") == 0, "daylight correctly clears night treatment")
	game.show_inventory()
	await frames()
	var scroll: ScrollContainer = game.modal.get_node("ModalCard/Layout/Scroll")
	check(scroll.get_h_scroll_bar().max_value <= scroll.size.x + 1 and scroll.get_v_scroll_bar().max_value <= scroll.size.y + 1, "restyled inventory fits viewport without unwanted scrolling")
	await capture("art16-inventory")
	game.close_modal()
	var gear: Dictionary = game.state.grant_gear("prajna", 2)
	game.state.equip(gear.id)
	game.show_equipment()
	await capture("art16-equipment")
	game.close_modal()
	game.travel("graveyard")
	game.player.position = Vector2(480, 470)
	await capture("art16-graveyard")
	game.travel("island")
	game.player.position = Vector2(640, 1024)
	await capture("art16-island")
	game.travel("temple")
	game.state.minutes = 1120
	game.player.position = Vector2(1136, 240)
	await capture("art16-temple")
	check(game.world.is_safe_position(game.player.position), "temple art keeps actual traversal safe")
	var enemy: YinEnemy = get_nodes_in_group("enemies").filter(func(e): return e.record.zone == "temple")[0]
	enemy.set_physics_process(false)
	enemy.record.hp = enemy.record.max_hp
	enemy.receive_hit(roundi(enemy.record.max_hp * 0.78), "bullet")
	var fragments: Array = game.world.feedback.get_children().filter(func(n): return n is YinSeveredLimb)
	check(not fragments.is_empty() and fragments.all(func(n): return n.source_region.has_area() and n.draw_size.length() > 0 and n.source_texture == YinActorArt.ROSTER), "detached body parts use matching reference atlas regions")
	check(FarmState.new().restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))), "visual refactor preserves valid persisted gameplay data")
	game.queue_free()
	await frames()
	print("ART16 RESULT ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
