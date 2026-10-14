extends SceneTree
var failures: int = 0
var checks: int = 0
var game: Node2D
func check(condition: bool, name_text: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + name_text)

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	game.state = FarmState.new()
	game.world.state = game.state
	game.player.position = Vector2(300, 210)
	check(game.player is CharacterBody2D and game.player.get_child_count() >= 2, "player with collision and camera")
	check(game.world.obstacles.size() > 40, "world colliders created")
	check(not game.world.is_safe_position(Vector2(660, 150)), "river is impassable")
	check(game.world.is_safe_position(Vector2(660, 256)), "bridge is passable")
	check(not game.world.is_safe_position(Vector2(150, 130)), "house is solid")
	var before: Vector2 = game.player.position
	Input.action_press("move_down")
	await frames(20)
	Input.action_release("move_down")
	check(game.player.position.y > before.y + 15, "WASD movement actually moves body")
	game.player.position = Vector2(617, 180)
	await frames(3)
	Input.action_press("move_right")
	await frames(35)
	Input.action_release("move_right")
	check(game.player.position.x < 635, "physics blocks entering river")
	game.player.position = Vector2(617, 256)
	await frames(3)
	Input.action_press("move_right")
	await frames(75)
	Input.action_release("move_right")
	check(game.player.position.x > 704, "player walks across bridge")
	game.player.position = Vector2(100, 300)
	game.tool = 0
	game.use_plot(0)
	check(not game.state.plots[0].tilled, "cannot work on distant tile")
	game.player.position = Vector2(332, 291)
	game.player.facing = Vector2.UP
	game.action_cooldown = 0
	game.use_plot(0)
	check(game.state.plots[0].tilled, "nearby tile can be tilled")
	check(game.world.front_plot() == 0, "facing selects correct tile")
	game.show_inventory()
	var time_before: float = game.state.minutes
	before = game.player.position
	Input.action_press("move_right")
	await frames(15)
	Input.action_release("move_right")
	check(game.player.position == before, "dialog blocks movement")
	check(game.state.minutes == time_before, "dialog pauses clock")
	game.close_modal()
	game.player.position = FarmWorld.NPC + Vector2(0, 20)
	check(game.world.nearest_interaction() == "npc", "NPC proximity interaction")
	game.state.total_harvest = 3
	game.interact()
	check(game.state.quest_claimed and game.state.money == 220, "NPC reward through scene interaction")
	game.player.position = FarmWorld.SHOP + Vector2(0, 20)
	game.interact()
	check(game.modal != null and game.player.frozen, "shop opens proximity dialog")
	game.close_modal()
	game.advance_day()
	check(game.state.day == 2 and game.state.energy == 100 and game.player.position == Vector2(160, 217), "sleep advances day and returns home")
	check(game.world.is_safe_position(game.player.position), "wake-up position is outside collision")
	print("World integration: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await frames(2)
	quit(1 if failures else 0)
