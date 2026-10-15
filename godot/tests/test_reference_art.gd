extends SceneTree
var checks: int = 0
var failures: int = 0
var game: Node2D
var folder: String
class Stage extends Node2D:
	var mode: int = 0
	var clock: float = 0
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 1080), Color("273332"))
		var font: Font = ThemeDB.fallback_font
		if mode == 0:
			draw_string(font, Vector2(30, 30), "YINTIAN 0.16 / ENEMY ROSTER / IN-ENGINE SPRITES", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("dfcfaf"))
			for i in range(YinBalance.MONSTERS.size()):
				var kind: String = YinBalance.MONSTERS.keys()[i]
				var at := Vector2(128 + (i % 5) * 250, 216 + (i / 5) * 204)
				draw_set_transform(at, 0, Vector2(2, 2))
				var pose: Dictionary = YinActorArt.enemy_pose(kind, Vector2.DOWN, clock, true, false, false)
				YinActorArt.draw_enemy(self, kind, pose, [], clock, true, false, Color.WHITE)
				draw_set_transform(Vector2.ZERO)
				draw_string(font, at + Vector2(-85, 24), kind, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("d1b99a"))
		elif mode == 1:
			draw_string(font, Vector2(30, 30), "HERO / IDLE - STEP A - STEP B - WINDUP - RELEASE - HIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("dfcfaf"))
			for row in range(4):
				for column in range(6):
					var at := Vector2(108 + column * 210, 210 + row * 212)
					draw_set_transform(at, 0, Vector2(2.2, 2.2))
					YinActorArt.draw_pose(self, YinActorArt.hero_pose([Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][row], column))
					draw_set_transform(Vector2.ZERO)
		elif mode == 2:
			draw_string(font, Vector2(30, 30), "DAITENGU / IDLE - WALK - WING STRIKE - DISMEMBERED", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("dfcfaf"))
			for row in range(4):
				for column in range(4):
					var at := Vector2(150 + column * 320, 235 + row * 255)
					draw_set_transform(at, 0, Vector2(2.0, 2.0))
					var direction: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][row]
					var pose: Dictionary = YinActorArt.enemy_pose("daitengu", direction, 0.18, column == 1, column == 2, true)
					YinActorArt.draw_enemy(self, "daitengu", pose, ["arm", "leg", "head"] if column == 3 else [], 0.18, column == 1, column == 2, Color.WHITE)
					draw_set_transform(Vector2.ZERO)
		else:
			draw_string(font, Vector2(30, 36), "YINTIAN 0.16 / RUNTIME ANIMATION PREVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("dfcfaf"))
			for i in range(4):
				var direction: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][i]
				var attack: float = maxf(0, 0.22 - fmod(clock, 1.0))
				draw_set_transform(Vector2(150 + i * 320, 300), 0, Vector2(2.5, 2.5))
				YinActorArt.draw_pose(self, YinActorArt.hero_pose(direction, YinActorArt.hero_column(clock, true, attack, 0)))
				draw_set_transform(Vector2(150 + i * 320, 605), 0, Vector2(2.2, 2.2))
				var pose: Dictionary = YinActorArt.enemy_pose("daitengu", direction, clock, true, attack > 0, true)
				YinActorArt.draw_enemy(self, "daitengu", pose, [], clock, true, attack > 0, Color.WHITE)
				draw_set_transform(Vector2.ZERO)

func check(ok: bool, message: String) -> void:
	checks += 1
	print("REFERENCE ", "PASS " if ok else "FAIL ", message)
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
	if folder == "" or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name_value + ".png")) == OK, "capture actual game " + name_value)
func run() -> void:
	var atlas: Dictionary = YinActorArt.atlas()
	check(atlas.hero.size() == 4 and atlas.hero.all(func(row): return row.size() == 6), "24 hero direction and action poses indexed")
	check(atlas.tengu.size() == 4 and atlas.tengu.all(func(row): return row.size() == 4), "16 bird enemy direction and wing poses indexed")
	for kind in YinBalance.MONSTERS:
		var pose: Dictionary = YinActorArt.enemy_pose(kind, Vector2.LEFT, 0.2, true, false, kind in YinAbilities.BOSSES)
		var texture_bounds := Rect2(Vector2.ZERO, pose.texture.get_size())
		var parts: Array = YinActorArt.pieces(kind, pose)
		var area: float = 0
		var valid: bool = texture_bounds.encloses(pose.source)
		for i in range(parts.size()):
			area += parts[i].rect.get_area()
			for j in range(i): valid = valid and not parts[i].rect.intersects(parts[j].rect)
		check(valid and is_equal_approx(area, 1), kind + " source valid; anatomy covers exactly whole sprite without overlap")
	for direction in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
		var idle: Dictionary = YinActorArt.hero_pose(direction, 0)
		check(is_zero_approx(idle.destination.end.y) and is_equal_approx(idle.destination.size.y, 58), "hero feet stay anchored in direction " + str(direction))
	check(YinActorArt.hero_column(0, false, 0.2, 0) == 3 and YinActorArt.hero_column(0, false, 0.05, 0) == 4 and YinActorArt.hero_column(0, false, 0, 0.15) == 5, "attack windup release and hit select real distinct poses")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.close_modal()
	game.state.intro_seen = true
	game.state.factions.last_day = game.state.day
	game.state.minutes = 900
	game.state.weather = "sun"
	game.travel("village")
	game.player.position = Vector2(540, 256)
	await capture("actors-village")
	game.state.island_journal.defeated = ["itsumade"]
	game.travel("island")
	await frames()
	var enemy: YinEnemy = get_nodes_in_group("enemies").filter(func(e): return e.record.kind == "daitengu")[0]
	enemy.set_physics_process(false)
	game.player.position = Vector2(1480, 360)
	enemy.position = Vector2(1568, 350)
	enemy.art_strike = 0.18
	await capture("actors-tengu-intact")
	var pose: Dictionary = enemy.art_pose()
	check(pose.texture == YinActorArt.TENGU, "live daitengu selects new action atlas")
	enemy.record.hp = roundi(enemy.record.max_hp * 0.12)
	enemy.update_dismemberment()
	var fragments: Array = game.world.feedback.get_children().filter(func(n): return n is YinSeveredLimb)
	check(enemy.record.severed == ["arm", "leg", "head"] and fragments.size() == 3, "live enemy detaches all three distinct parts at thresholds")
	check(fragments.all(func(n): return n.source_texture == YinActorArt.TENGU and n.source_region.has_area() and n.draw_size.length() > 0), "fragments use current new pose regions and exact rendered scale")
	var hp: int = game.state.health
	enemy.victim = game.player
	enemy.hurt_victim(20)
	check(game.state.health == hp, "headless enemy cannot attack player")
	await capture("actors-tengu-severed")
	check(FarmState.new().restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))), "new art and severed state preserve save round trip")
	# Check the actual animation clock observes gameplay pause and freezing.
	enemy.record.severed = []
	enemy.freeze_lock = 0.8
	enemy.set_physics_process(true)
	var before: float = enemy.art_clock
	await frames(4)
	check(enemy.art_clock == before, "frozen enemy holds its animation frame")
	game.show_pause()
	await frames(3)
	check(enemy.art_clock == before, "pause holds enemy animation frame")
	game.close_modal()
	game.queue_free()
	await frames()
	if folder != "" and DisplayServer.get_name() != "headless":
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1280, 1080)
		viewport.world_2d = World2D.new()
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var stage := Stage.new()
		viewport.add_child(stage)
		for mode in range(3):
			stage.mode = mode
			stage.queue_redraw()
			await frames()
			await RenderingServer.frame_post_draw
			check(viewport.get_texture().get_image().save_png(folder.path_join(["actors-roster", "actors-hero-poses", "actors-tengu-poses"][mode] + ".png")) == OK, "capture in-engine atlas gallery " + str(mode))

		stage.mode = 3
		viewport.size = Vector2i(1280, 720)
		var animation_folder: String = folder.path_join("action-frames")
		DirAccess.make_dir_recursive_absolute(animation_folder)
		for i in range(24):
			stage.clock = float(i) / 12.0
			stage.queue_redraw()
			await frames(2)
			await RenderingServer.frame_post_draw
			check(viewport.get_texture().get_image().save_png(animation_folder.path_join("frame-%03d.png" % i)) == OK, "runtime animation frame " + str(i))
		viewport.queue_free()
	print("REFERENCE RESULT ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
