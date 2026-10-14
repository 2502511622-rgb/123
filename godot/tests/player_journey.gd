extends SceneTree
var checks := 0
var failures := 0
var game: Node2D
var started: int = Time.get_ticks_msec()
func _process(_delta: float) -> bool:
 if Time.get_ticks_msec() - started > 55000:
  push_error("Player journey timed out")
  quit(1)
 return false
func check(ok: bool, text: String) -> void:
 checks += 1
 print("PLAYER ", "PASS " if ok else "FAIL ", text)
 if not ok: failures += 1
func _initialize() -> void:
 OS.set_environment("YINTIAN_SILENT", "1")
 call_deferred("run")
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func key(code: int) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = code
 event.keycode = code
 event.pressed = true
 Input.parse_input_event(event)
 Input.flush_buffered_events()
 await frames(2)
 event = InputEventKey.new()
 event.physical_keycode = code
 event.keycode = code
 event.pressed = false
 Input.parse_input_event(event)
 Input.flush_buffered_events()
 await frames(2)
func click(node: Control) -> void:
 await process_frame
 var at: Vector2 = node.get_global_rect().get_center()
 var event := InputEventMouseButton.new()
 event.position = at
 event.global_position = at
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = true
 root.push_input(event, true)
 await frames(2)
 event = InputEventMouseButton.new()
 event.position = at
 event.global_position = at
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = false
 root.push_input(event, true)
 await frames(2)
func buttons(node: Node) -> Array:
 if node == null: return []
 var found: Array = []
 for child in node.get_children():
  if child is Button: found.append(child)
  found.append_array(buttons(child))
 return found
func choose(fragment: String) -> bool:
 for node in buttons(game.modal):
  if fragment in node.text:
   var ancestor: Node = node.get_parent()
   while ancestor != null:
    if ancestor is ScrollContainer: ancestor.ensure_control_visible(node)
    ancestor = ancestor.get_parent()
   await process_frame
   await click(node)
   return true
 return false
func release_movement() -> void:
 for action in ["move_left", "move_right", "move_up", "move_down"]: Input.action_release(action)
func walk(at: Vector2, limit: int = 240) -> bool:
 for i in range(limit):
  var difference: Vector2 = at - game.player.position
  if difference.length() < 4:
   release_movement()
   await frames(2)
   return true
  release_movement()
  if absf(difference.x) > 2: Input.action_press("move_right" if difference.x > 0 else "move_left")
  if absf(difference.y) > 2: Input.action_press("move_down" if difference.y > 0 else "move_up")
  await physics_frame
 release_movement()
 print("WALK blocked: ", game.player.position, " target ", at)
 return false
func run() -> void:
 Engine.time_scale = 3
 var title: Control = load("res://scenes/ui/title_screen.tscn").instantiate()
 root.add_child(title)
 current_scene = title
 await frames(8)
 await click(buttons(title)[0])
 if is_instance_valid(title) and title.confirmation.visible: await click(title.confirmation.get_ok_button())
 await frames(8)
 if not current_scene.has_method("use_plot"):
  check(false, "title new-game mouse click")
  quit(1)
  return
 game = current_scene
 check(game.modal != null, "new game opens readable letter")
 check(await choose("收起遗书"), "letter dismiss by mouse")
 check(game.modal == null and not game.player.frozen, "letter releases player input")
 check(await walk(Vector2(285, 350)) and await walk(Vector2(285, 218)) and await walk(Vector2(160, 218)), "walk from starting field to hall door")
 await key(KEY_E)
 check(game.state.zone == "hall", "E enters hall from starting door")
 if game.state.zone != "hall": quit(1); return
 check(await walk(Vector2(480, 380)) and await walk(Vector2(306, 380)), "walk to warehouse without furniture snag")
 await key(KEY_E)
 check(game.modal != null, "E opens warehouse")
 await key(KEY_ESCAPE)
 check(await walk(Vector2(480, 380)) and await walk(Vector2(480, 439)), "walk to indoor exit")
 await key(KEY_E)
 check(game.state.zone == "farm", "exit preserves farm spawn")
 check(await walk(Vector2(285, 218)) and await walk(Vector2(285, 350)) and await walk(Vector2(336, 350)) and await walk(Vector2(336, 291)), "farm entrance is physically navigable")
 game.choose_tool(0)
 await frames(2)
 await key(KEY_SPACE)
 await frames(15)
 game.choose_tool(1)
 await frames(2)
 await key(KEY_SPACE)
 await frames(15)
 game.choose_tool(2)
 await frames(2)
 await key(KEY_SPACE)
 check(game.state.plots[0].tilled and game.state.plots[0].crop == "candle" and game.state.plots[0].watered, "keyboard till, sow and water same reachable plot")
 await key(KEY_I)
 var pose: Vector2 = game.player.position
 var minute: float = game.state.minutes
 Input.action_press("move_right")
 await frames(10)
 release_movement()
 check(game.player.position == pose and game.state.minutes == minute, "bag freezes movement and world clock")
 await key(KEY_ESCAPE)
 check(await walk(Vector2(336, 350)) and await walk(Vector2(285, 350)) and await walk(Vector2(285, 510)) and await walk(Vector2(620, 510)) and await walk(Vector2(620, 256)) and await walk(Vector2(730, 256)), "field exit and bridge route without teleport")
 check(await walk(Vector2(730, 450)) and await walk(Vector2(846, 450)) and await walk(Vector2(846, 501)), "walk to cemetery gate")
 await key(KEY_E)
 check(game.state.zone == "graveyard", "E enters exploration zone")
 # Approach a live enemy using movement; no direct damage calls.
 var foe: YinEnemy = game.nearest_enemy(game.player.position, 1000)
 var record: Dictionary = foe.record
 for i in range(240):
  if game.player.position.distance_to(foe.position) < 95: break
  release_movement()
  var direction: Vector2 = game.player.position.direction_to(foe.position)
  if absf(direction.x) > 0.15: Input.action_press("move_right" if direction.x > 0 else "move_left")
  if absf(direction.y) > 0.15: Input.action_press("move_down" if direction.y > 0 else "move_up")
  await physics_frame
 release_movement()
 await key(KEY_F)
 check(foe.stun > 2 and record.integrity == 100, "keyboard seal suppresses live target")
 for i in range(8):
  if record.dead: break
  if not is_instance_valid(foe): break
  await walk(foe.position + Vector2(0, 28), 100)
  game.player.facing = Vector2.UP
  await key(KEY_J)
  await frames(10)
 check(record.dead and not game.state.remains.is_empty(), "keyboard melee leaves intact remains")
 if record.dead:
  var remains: Dictionary = game.state.remains[0]
  await walk(Vector2(remains.at[0], remains.at[1]) + Vector2(0, 20), 100)
  await key(KEY_E)
  check(await choose("装车带回"), "corpse interaction opens actual load action")
  check(game.state.cargo.size() == 1, "load corpse through UI")
  if game.modal != null: await key(KEY_ESCAPE)
  check(await walk(Vector2(180, 515)) and await walk(Vector2(180, 540)), "loaded cart can physically return")
  await key(KEY_E)
  check(game.state.zone == "farm" and game.state.cargo.size() == 1, "return keeps transported remains")
  check(await walk(Vector2(730, 538)) and await walk(Vector2(730, 256)) and await walk(Vector2(620, 256)) and await walk(Vector2(620, 218)) and await walk(Vector2(285, 218)) and await walk(Vector2(160, 218)), "loaded cart returns across bridge to hall door")
  await key(KEY_E)
  check(game.state.zone == "hall" and await walk(Vector2(480, 285)), "transport reaches indoor workbench")
  await key(KEY_E)
  check(await choose("处理运输车"), "workbench exposes transported corpse")
  check(await choose("炼为役灵"), "refinement activated through scrollable UI")
  check(game.state.spirits.size() == 1 and game.state.cargo.is_empty(), "full fight-transport-refine loop creates a worker")
  if game.modal != null: await key(KEY_ESCAPE)
  check(game.modal == null and not game.player.frozen, "refinement returns to active play")
 # Focused adversarial collision case, with explicit test fixture.
 game.state = FarmState.new()
 game.build_zone("farm", Vector2(618, 180))
 await frames(4)
 var blocked := {"id": 900, "kind": "water", "zone": "farm", "at": [722,180], "hp": 100, "max_hp": 100, "integrity": 100, "suppressed": false, "dead": false}
 game.state.enemies.append(blocked)
 game.spawn_enemies()
 await frames(3)
 var stock: int = game.state.talismans
 await key(KEY_F)
 check(blocked.hp == 100 and game.state.talismans == stock, "wall blocks spell and preserves talisman")
 var enemy: YinEnemy = game.nearest_enemy(Vector2(722,180), 30)
 enemy.attack_center = game.player.position
 enemy.windup = 0.01
 var life: int = game.state.health
 await frames(3)
 check(game.state.health == life, "enemy attack cannot cross river wall")
 game.player.position = Vector2(480, 350)
 enemy.position = Vector2(450, 350)
 await frames(3)
 check(not game.player.hitbox.targets(Vector2.RIGHT).has(enemy), "sword cone excludes enemy behind player")
 enemy.attack_center = game.player.position
 enemy.windup = 0.2
 await key(KEY_SHIFT)
 await frames(5)
 check(game.state.health == life, "dodge invulnerability avoids telegraphed hit")
 game.player.state_machine.reset()
 game.player.position = Vector2(480, 350)
 game.player.facing = Vector2.RIGHT
 enemy.position = Vector2(512, 350)
 enemy.stun = 3
 enemy.record.hp = 100
 game.action_cooldown = 0
 await frames(2)
 await key(KEY_7)
 game.attack("sword")
 check(enemy.record.hp == 100 and not game.combat.pending.is_empty(), "sword damage occurs on contact frame rather than key-down")
 game.show_inventory()
 await frames(5)
 check(enemy.record.hp == 100, "modal freezes pending strike")
 game.close_modal()
 await frames(4)
 var after_hit: int = enemy.record.hp
 await frames(12)
 check(after_hit == 85 and enemy.record.hp == after_hit, "one swing hits each target exactly once")
 game.player.position = Vector2(617, 180)
 game.player.facing = Vector2.RIGHT
 game.player.state_machine.reset()
 game.player.dodge_cooldown = 0
 await frames(2)
 await key(KEY_SHIFT)
 await frames(8)
 check(game.player.position.x < 635, "dodge cannot phase through river wall")
 print("Player journey: ", checks, " checks, ", failures, " failures")
 game.queue_free()
 await frames(3)
 quit(1 if failures else 0)
