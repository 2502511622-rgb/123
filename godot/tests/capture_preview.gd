extends SceneTree
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT", "1")
	call_deferred("capture")
func capture() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--title" in args:
		var title: Control = load("res://scenes/ui/title_screen.tscn").instantiate()
		root.add_child(title)
		for i in range(12): await process_frame
		await RenderingServer.frame_post_draw
		quit(root.get_texture().get_image().save_png(args[0]))
		return
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(12): await process_frame
	if "--intro" not in args:
		game.close_modal()
		game.state.intro_seen = true
		game.state.day = 9 if "--night" in args else 6
		game.state.hall_level = 2
		game.state.minutes = 1140 if "--night" in args else 630
		game.state.spirits = [game.state.make_spirit("water", 20), game.state.make_spirit("bone", 16), game.state.make_spirit("child", 8)]
		for i in range(32):
			game.state.plots[i].tilled = true
			game.state.plots[i].crop = ["candle", "vine", "gourd", "rice"][int(i / 8)]
			game.state.plots[i].growth = FarmState.CROPS[game.state.plots[i].crop].growth_days
			game.state.plots[i].watered = i % 3 == 0
		var zone: String = "graveyard" if "--cemetery" in args or "--combat" in args else ("hall" if "--hall" in args or "--warehouse" in args else "farm")
		game.state.supplies.wood = 8
		game.state.supplies.stone = 6
		game.state.supplies.paper_lamp = 2
		game.build_zone(zone, Vector2(480, 340) if zone == "hall" else Vector2(450, 310))
		var camera: Camera2D = game.player.get_node("Camera2D")
		camera.zoom = Vector2(0.75, 0.75)
		camera.position_smoothing_enabled = false
		game.refresh("乱葬坡：杀鬼留骸，带回义庄炼化。" if "--cemetery" in args else "义庄与阴植：白天经营，夜晚点名。")
		if "--warehouse" in args: game.show_storage()
		elif "--bag" in args: game.show_inventory()
		elif "--hall" in args: game.refresh("义庄内部：案台炼骸，仓箱存取，卧榻休息。")
	if "--combat" in args:
		for companion in get_nodes_in_group("companions"): companion.queue_free()
		game.player.position = Vector2(350, 423)
		game.player.facing = Vector2(30, -33).normalized()
		var target: YinEnemy = game.nearest_enemy(Vector2(380, 390), 60)
		if target != null: target.stun = 3
		var warning: YinEnemy = game.nearest_enemy(Vector2(280, 240), 60)
		if warning != null:
			warning.position = Vector2(438, 410)
			warning.attack_center = game.player.position
			warning.windup = 0.7
		game.attack("sword")
		game.refresh("前方剑弧命中 · 伤害数字 · 躲开地面蓄力圈")
	game.player.frozen = true
	if "--combat" in args:
		for i in range(6): await physics_frame
		Engine.time_scale = 0
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	var target: String = args[0] if not args.is_empty() else "user://preview.png"
	var result: int = root.get_texture().get_image().save_png(target)
	print("Screenshot: ", target, " result=", result)
	quit(result)
