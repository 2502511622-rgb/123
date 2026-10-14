extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(12):
		await process_frame
	if "--showcase" in OS.get_cmdline_user_args():
		game.player.position = Vector2(450, 310)
		var camera: Camera2D = game.player.get_node("Camera2D")
		camera.zoom = Vector2(0.75, 0.75)
		camera.position_smoothing_enabled = false
		game.state.day = 5
		game.state.minutes = 630
		for i in range(24):
			game.state.plots[i].tilled = true
			game.state.plots[i].crop = ["turnip", "carrot", "tomato"][int(i / 8)]
			game.state.plots[i].growth = 3 + int(i / 8)
			game.state.plots[i].watered = i % 3 == 0
		game.refresh("青苔小院：三种作物、河畔小铺与春日的慢生活。")
	game.player.frozen = true
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var target: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://preview.png"
	var image := root.get_texture().get_image()
	var result: int = image.save_png(target)
	print("Screenshot: ", target, " result=", result)
	quit(result)
