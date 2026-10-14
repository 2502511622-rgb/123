extends SceneTree
func _initialize() -> void:
	OS.set_environment("YINTIAN_SILENT", "1")
	call_deferred("capture")
func capture() -> void:
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(12): await process_frame
	var args: PackedStringArray = OS.get_cmdline_user_args()
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
		game.build_zone("graveyard" if "--cemetery" in args else "farm", Vector2(450, 310))
		var camera: Camera2D = game.player.get_node("Camera2D")
		camera.zoom = Vector2(0.75, 0.75)
		camera.position_smoothing_enabled = false
		game.refresh("乱葬坡：杀鬼留骸，带回义庄炼化。" if "--cemetery" in args else "义庄与阴植：白天经营，夜晚点名。")
		if "--hall" in args: game.show_hall()
	game.player.frozen = true
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	var target: String = args[0] if not args.is_empty() else "user://preview.png"
	var result: int = root.get_texture().get_image().save_png(target)
	print("Screenshot: ", target, " result=", result)
	quit(result)
