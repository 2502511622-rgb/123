extends SceneTree
var checks: int = 0
var failures: int = 0
var game: Node2D
var folder: String
func check(ok: bool, text: String) -> void:
	checks += 1
	print("WEATHER ", "PASS " if ok else "FAIL ", text)
	if not ok: failures += 1
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT", "1")
	folder = OS.get_environment("YINTIAN_CAPTURE_DIR")
	call_deferred("run")
func frames(count: int = 4) -> void:
	for i in range(count): await physics_frame
func capture(name_value: String) -> void:
	game.player.get_node("Camera2D").reset_smoothing()
	game.player.get_node("Camera2D").force_update_scroll()
	await frames()
	if DisplayServer.get_name() == "headless" or folder == "": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name_value + ".png")) == OK, "capture " + name_value)
func run() -> void:
	check(is_equal_approx(YinLightField.hit_distance(Vector2.ZERO, Vector2.RIGHT, Rect2(10, -5, 10, 10), 100), 10), "light ray stops at nearest opaque wall")
	check(is_equal_approx(YinLightField.hit_distance(Vector2.ZERO, Vector2.RIGHT, Rect2(10, 5, 10, 10), 100), 100), "parallel clear light ray keeps full radius")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.close_modal()
	game.state.intro_seen = true
	game.state.factions.last_day = game.state.day
	game.state.weather = "rain"
	game.state.minutes = 1260
	game.travel("village")
	game.player.position = Vector2(540, 256)
	await frames(8)
	var env: YinEnvironment = game.world.environment
	check(env.baked and env.rain > 0.9 and env.wetness > 0.7, "rainy destination loads already wet rather than resetting weather")
	check(env.light_field.viewport.world_2d != game.world.get_world_2d(), "light mask is isolated from gameplay physics and canvas")
	check(env.light_field.blocked_rays > 0 and not env.light_field.sources.is_empty(), "actual scene light polygons include wall occlusion")
	check(env.ground_mask.get_width() == 40 and env.ground_mask.get_height() == 30, "wet reflection mask matches actual map tile grid")
	check(not env.reflections.is_empty() and env.reflections.any(func(r): return r.texture == YinArt.texture("cottage")), "houses produce actual mirrored source-sprite reflections")
	var field: YinLightField = env.light_field
	var cache_revision: int = field.count
	var clock_before: float = env.time
	await frames(40)
	check(env.time > clock_before and field.count == cache_revision, "wind animates without rebuilding static occlusion every frame")
	check(not env.splashes.is_empty() and env.splashes.all(func(s): return env.exposed(s.at)), "rain splashes spawn only on exposed navigable surfaces")
	for i in range(90): env.emit_leaf()
	check(env.leaves.size() == 54, "visible tree leaf population is bounded")
	check(env.leaves.all(func(leaf): return leaf.height > 0), "fresh leaves begin aloft above actual nearby trees")
	var leaf_at: Vector2 = env.leaves[0].at
	var leaf_height: float = env.leaves[0].height
	await frames(12)
	check(env.leaves[0].at != leaf_at and env.leaves[0].height < leaf_height, "leaves drift and fall instead of being screen-space decorations")
	var tree: Node2D = get_nodes_in_group("wind_trees").filter(func(t): return t.get_parent() == game.world.actors and t.position == Vector2(416, 254))[0]
	var trunk_at: Vector2 = tree.position
	var tree_sprite: Sprite2D = tree.get_node("ArtSprite")
	check(tree_sprite is YinWindSprite and tree_sprite.material.get_shader_parameter("wind") > 0, "real tree sprite receives shared wind uniforms")
	await frames(12)
	check(tree.position == trunk_at, "wind leaves the trunk collision anchor fixed")
	game.show_pause()
	var paused_time: float = env.time
	var paused_leaf_age: float = env.leaves[0].age
	await frames(15)
	check(env.time == paused_time and env.leaves[0].age == paused_leaf_age, "pause freezes wind rain ripples and leaves")
	game.close_modal()
	game.player.position += Vector2(22, 0)
	await frames()
	check(not env.footsteps.is_empty(), "wet footsteps create world-space ripples")
	await capture("weather-village-rain-night")
	if DisplayServer.get_name() != "headless" and folder != "":
		var frame_folder: String = folder.path_join("rain-frames")
		DirAccess.make_dir_recursive_absolute(frame_folder)
		var times: Array[float] = []
		for i in range(36):
			await frames(3)
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(frame_folder.path_join("frame-%03d.png" % i)) == OK, "rain animation frame %d" % i)
			times.append(env.time)
		check(times[-1] > times[0], "captured animation contains real advancing weather")
	game.state.weather = "sun"
	await frames(12)
	check(env.wetness > 0.5 and env.rain < 1, "rain fades while damp ground dries gradually")
	game.state.minutes = 600
	await capture("weather-village-damp-day")
	var old_position: Vector2 = game.player.position
	game.player.position = tree.position + Vector2(0, -38)
	await frames(30)
	check(tree_sprite.modulate.a < 0.9, "canopy fades when player walks underneath")
	game.player.position = old_position
	var obstacle_count: int = game.world.obstacles.size()
	for i in range(3): tree.strike(4)
	await frames()
	check(game.world.obstacles.size() == obstacle_count - 1 and field.count > cache_revision, "felling tree invalidates physics occlusion and visual caches")
	check(env.reflections.all(func(r): return r.get_meta("source").get_ref() != null), "removed trees leave no live reflection sources")
	game.state.weather = "rain"
	game.travel("hall")
	await frames(10)
	var interior: YinEnvironment = game.world.environment
	check(interior.indoor and interior.rain == 0 and interior.leaves.is_empty() and interior.splashes.is_empty(), "outdoor rain and leaves stop at interior boundary")
	await capture("weather-interior-dry")
	game.travel("farm")
	game.player.position = Vector2(578, 264)
	await frames(10)
	check(game.world.environment.terrain_material.get_shader_parameter("wetness") > 0.7, "river shader receives real wet weather state")
	await capture("weather-farm-river")
	game.state.minutes = 1260
	await capture("weather-farm-river-night")
	check(FarmState.new().restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))), "dynamic visual systems preserve save compatibility")
	game.queue_free()
	await frames()
	print("WEATHER RESULT ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
