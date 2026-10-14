extends SceneTree
var checks: int = 0
var failures: int = 0
var game: Node2D
var shots: int = 0
func check(ok: bool, text: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("FAIL: " + text)
func _initialize() -> void:
 OS.set_environment("YINTIAN_SILENT", "1")
 call_deferred("run")
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func key(code: int) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = code
 event.pressed = true
 Input.parse_input_event(event)
 Input.flush_buffered_events()
 await frames(2)
 event = InputEventKey.new()
 event.physical_keycode = code
 event.pressed = false
 Input.parse_input_event(event)
 Input.flush_buffered_events()
 await frames(2)
func buttons(node: Node) -> Array:
 var result: Array = []
 for child in node.get_children():
  if child is Button: result.append(child)
  result.append_array(buttons(child))
 return result
func click_button(button: Button) -> void:
 var parent: Node = button.get_parent()
 while parent != null:
  if parent is ScrollContainer: parent.ensure_control_visible(button)
  parent = parent.get_parent()
 await process_frame
 var at: Vector2 = button.get_global_rect().get_center()
 for pressed in [true, false]:
  var event := InputEventMouseButton.new()
  event.position = at
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  root.push_input(event, true)
  await frames(2)
func fixture(kind: String, at: Vector2, hp: int = 1000) -> YinEnemy:
 var record: Dictionary = game.state.spawn_record(kind, "farm", at, 1)
 record.hp = hp
 record.max_hp = hp
 record.armor = 0
 var enemy: YinEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
 enemy.game = game
 enemy.record = record
 enemy.position = at
 enemy.stun = 100
 enemy.add_to_group("enemies")
 game.world.actors.add_child(enemy)
 return enemy
func reset_world(at: Vector2) -> void:
 game.close_modal()
 game.state = FarmState.new()
 game.build_zone("farm", at)
 game.state.enemies.clear()
 game.action_cooldown = 0
func run() -> void:
 Engine.time_scale = 3
 check(YinBalance.MONSTERS.size() == 9, "nine independent monster archetypes")
 check(YinBalance.damage(15, 1) == 15 and YinBalance.damage(0, 1) == 0, "baseline and zero damage")
 check(YinBalance.damage(20, 1, {}, 100) == 10, "armor uses diminishing returns")
 check(YinBalance.damage(20, 3, YinBalance.make_gear(1, "rifle", 4, 2)) > 20, "level tier and quality increase damage")
 check(YinBalance.enemy("brute", 3, true).hp > YinBalance.enemy("brute", 1).hp, "elite and level scale enemy durability")
 var s := FarmState.new()
 s.prepare_enemies()
 check(s.enemies.filter(func(e): return e.zone == "forest").size() == 16, "expanded forest population")
 check(s.enemies.filter(func(e): return e.zone == "forest" and e.elite).size() == 2, "two forest elites")
 var elite: Dictionary = s.enemies.filter(func(e): return e.zone == "forest" and e.elite)[0]
 s.kill_enemy(elite.id, Vector2(1100, 700))
 check(s.gear_drops.all(func(drop): return drop.gear.quality >= 1), "elite equipment, when rolled, has magic quality or better")
 check(s.drops.any(func(drop): return drop.item in ["light_ammo", "rifle_ammo"]) and not s.remains.is_empty(), "ammo drop coexists with corpse")
 var gear_count: int = s.gear_drops.size()
 var material_count: int = s.drops.size()
 s.kill_enemy(elite.id, Vector2(1100, 700))
 check(s.gear_drops.size() == gear_count and s.drops.size() == material_count, "repeated death cannot duplicate rewards")
 s.process_remains(s.remains[0].id, "refine")
 check(s.spirits.size() == 1 and s.remains.is_empty(), "ordinary ranged monster can be instantly refined into a companion")
 s.zone = "forest"
 s.player_position = Vector2(1500, 800)
 s.saved_facing = Vector2(1, 1).normalized()
 var restored := FarmState.new()
 check(restored.restore(JSON.parse_string(JSON.stringify(s.snapshot()))) and restored.gear_drops == s.gear_drops, "expanded coordinates diagonal aim and unique drops survive JSON")
 var old: Dictionary = FarmState.new().snapshot()
 old.version = 4
 for field in ["equipment", "gear_drops", "equipped_gear", "equipped_armor", "next_gear_id", "smart_farming"]: old.erase(field)
 for id in ["light_ammo", "rifle_ammo", "scrap"]:
  old.supplies.erase(id)
  old.storage.erase(id)
 old.bag_slots = []
 check(restored.restore(old) and restored.equipment.size() == 2 and restored.supplies.light_ammo == 36, "schema four migrates with starter gun and ammo")
 var bad: Dictionary = s.snapshot()
 bad.equipment[0].magazine = 999
 check(not restored.restore(bad), "magazine over capacity is rejected atomically")
 bad = s.snapshot()
 bad.equipment[0].bonus = 999
 check(not restored.restore(bad), "forged gear bonus rejected")
 bad = s.snapshot()
 bad.equipped_gear = 999999
 check(not restored.restore(bad), "dangling equipped item rejected")
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await frames(4)
 reset_world(Vector2(336, 291))
 game.player.facing = Vector2.UP
 await frames(3)
 await key(KEY_SPACE)
 await frames(8)
 await key(KEY_SPACE)
 await frames(8)
 await key(KEY_SPACE)
 check(game.state.plots[0].tilled and game.state.plots[0].crop == "candle" and game.state.plots[0].watered, "smart space key tills sows and waters without tool switching")
 var energy: int = game.state.energy
 await frames(8)
 await key(KEY_SPACE)
 check(game.state.energy >= energy, "smart already-watered plot does not spend energy during natural regeneration")
 game.choose_tool(3)
 await frames(2)
 check(not game.state.smart_farming and game.player.held_item == "tool3", "manual key overrides automation and changes held tool")
 await key(KEY_Z)
 check(game.state.smart_farming, "automation can be re-enabled")
 reset_world(Vector2(480, 350))
 var target: YinEnemy = fixture("bone", Vector2(515, 350), 100)
 game.player.facing = Vector2.RIGHT
 await frames(3)
 game.choose_tool(4)
 await frames(2)
 await key(KEY_J)
 await frames(10)
 check(target.record.hp == 76 and game.player.held_item == "tool4", "held axe is the actual melee weapon")
 target.record.hp = 100
 target.position = Vector2(560, 350)
 game.choose_tool(1)
 await frames(2)
 await key(KEY_J)
 check(target.record.hp == 100, "seed packet does not silently attack as a sword")
 await key(KEY_8)
 check(game.state.current_gear().weapon == "pistol" and game.player.held_item == "pistol", "pistol shortcut changes equipped and visible weapon")
 var reserve: int = game.state.supplies.light_ammo
 await key(KEY_U)
 await frames(24)
 check(game.state.current_gear().magazine == 8 and game.state.supplies.light_ammo == reserve - 8, "reload transfers reserve into magazine exactly once")
 check(not game.combat.reload(), "full magazine cannot consume more ammo")
 game.player.aim_direction = Vector2.RIGHT
 await key(KEY_J)
 await frames(10)
 check(target.record.hp == 81 and game.state.current_gear().magazine == 7, "actual pistol bullet deals damage and consumes one round")
 check(target.record.integrity == 100, "ballistic kill preparation preserves remains")
 var ammo_total: int = game.state.supplies.light_ammo
 var smg: Dictionary = game.state.grant_gear("smg")
 await key(KEY_9)
 await key(KEY_U)
 await frames(32)
 target.record.hp = 1000
 target.record.max_hp = 1000
 shots = 0
 var count_shots := func(friendly: bool):
  if friendly: shots += 1
 game.world.projectiles.projectile_spawned.connect(count_shots)
 Input.action_press("attack")
 await frames(12)
 Input.action_release("attack")
 await frames(4)
 check(smg.magazine <= 20 and target.record.hp < 970, "held attack makes SMG fire repeatedly")
 check(smg.magazine + game.state.supplies.light_ammo == ammo_total - shots and shots >= 4, "automatic fire consumes exactly one round per spawned bullet")
 game.world.projectiles.projectile_spawned.disconnect(count_shots)
 var rifle: Dictionary = game.state.grant_gear("rifle")
 game.state.supplies.rifle_ammo = 12
 await key(KEY_0)
 await key(KEY_U)
 await frames(36)
 check(rifle.magazine == 12 and game.state.supplies.rifle_ammo == 0, "rifle uses independent ammo pool")
 var before: int = target.record.hp
 await key(KEY_J)
 await frames(10)
 check(target.record.hp == before - 31 and rifle.magazine == 11, "rifle projectile damage and round consumption")
 rifle.magazine = 0
 check(not game.combat.shoot() and not game.combat.reload(), "empty gun with no reserve cannot shoot or reload")
 await key(KEY_8)
 await key(KEY_U)
 await frames(3)
 var old_stock: int = game.state.supplies.light_ammo
 await key(KEY_9)
 await frames(28)
 check(game.state.supplies.light_ammo == old_stock, "switching gun cancels reload without taking reserve")
 await key(KEY_8)
 await key(KEY_U)
 var waiting: float = game.combat.reload_job.get("remaining", 0)
 game.show_inventory()
 await frames(12)
 check(is_equal_approx(game.combat.reload_job.remaining, waiting), "inventory pauses reload timer")
 game.close_modal()
 await frames(24)
 check(game.state.current_gear().magazine == 8, "reload resumes after menu closes")
 var scrap_before: int = game.state.supplies.scrap
 rifle.magazine = 3
 game.state.weapon_slots.primary = 0
 check("拆解完成" in game.state.salvage(rifle.id) and game.state.supplies.rifle_ammo == 3 and game.state.supplies.scrap == scrap_before + 1, "salvage returns magazine ammo and parts")
 check("不可拆解" in game.state.salvage(game.state.equipped_gear), "equipped weapon cannot be accidentally salvaged")
 var armor: Dictionary = game.state.grant_gear("armor", 3, 2)
 game.state.equip(armor.id)
 var hp: int = game.state.health
 game.player.invincible = 0
 game.take_damage(20)
 check(game.state.health > hp - 18, "equipped armor actually reduces incoming damage")
 reset_world(Vector2(617, 180))
 target = fixture("bone", Vector2(722, 180))
 await frames(3)
 game.world.projectiles.spawn(Vector2(617, 176), Vector2.RIGHT, true, 100, 1800, 800, Color.WHITE)
 await frames(5)
 check(target.record.hp == 1000 and game.world.projectiles.bullets.is_empty(), "high speed bullet cannot tunnel across river wall")
 hp = game.state.health
 game.world.projectiles.spawn(Vector2(722, 176), Vector2.LEFT, false, 25, 1800, 800, Color.RED)
 await frames(5)
 check(game.state.health == hp, "wall blocks hostile bullets")
 reset_world(Vector2(480, 350))
 await frames(3)
 game.player.dodge()
 await frames(1)
 game.world.projectiles.spawn(game.player.position + Vector2(-20, -4), Vector2.RIGHT, false, 50, 800, 100, Color.RED)
 await frames(2)
 check(game.state.health == 100, "dodge avoids a real swept projectile")
 reset_world(Vector2(480, 350))
 await frames(3)
 for pattern in ["fan", "ring", "burst"]:
  var kind: String = {"fan": "archer", "ring": "lantern", "burst": "gunner"}[pattern]
  var ranged: YinEnemy = fixture(kind, Vector2(700, 350))
  ranged.stun = 0
  ranged.cooldown = 0
  game.world.projectiles.bullets.clear()
  shots = 0
  var connection := func(friendly: bool):
   if not friendly: shots += 1
  game.world.projectiles.projectile_spawned.connect(connection)
  await frames(28)
  check(shots == (12 if pattern == "ring" else 3), "actual telegraphed " + pattern + " enemy volley")
  game.world.projectiles.projectile_spawned.disconnect(connection)
  ranged.queue_free()
  await frames(2)
 game.world.projectiles.bullets.clear()
 game.world.projectiles.spawn(Vector2(800, 450), Vector2.RIGHT, true, 1, 100, 500, Color.WHITE)
 game.show_inventory()
 var position_before: Vector2 = game.world.projectiles.bullets[0].at
 await frames(5)
 check(game.world.projectiles.bullets[0].at == position_before, "modal freezes bullet simulation")
 game.close_modal()
 game.world.projectiles.bullets.clear()
 for i in range(YinProjectiles.LIMIT): game.world.projectiles.spawn(Vector2(800, 450), Vector2.RIGHT, true, 1, 100, 500, Color.WHITE)
 check(not game.world.projectiles.spawn(Vector2(800, 450), Vector2.RIGHT, true, 1, 100, 500, Color.WHITE), "projectile limit prevents unbounded allocations")
 game.travel("forest")
 await frames(3)
 check(game.world.level_size == Vector2(1920, 1280) and game.player.get_node("Camera2D").limit_right == 1920, "expanded forest has matching camera and collision bounds")
 check(game.world.projectiles.bullets.is_empty(), "scene switch clears old projectiles")
 check(not game.world.is_safe_position(Vector2(980, 300)) and game.world.is_safe_position(Vector2(980, 580)), "expanded river only permits bridge crossing")
 game.state.player_position = Vector2(1500, 800)
 check(restored.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))), "forest and expanded supplies serialize together")
 reset_world(Vector2(480, 350))
 var victim: YinEnemy = fixture("gunner", Vector2(515, 350))
 victim.record.elite = true
 victim.record.level = 2
 # Choose a deterministic death ID whose lower-rate loot table rolls equipment.
 while true:
  var probe := FarmState.new()
  probe.day = game.state.day
  probe.reward_enemy(victim.record, victim.position)
  if not probe.gear_drops.is_empty(): break
  victim.record.id += 1000
 game.state.next_id = maxi(game.state.next_id, victim.record.id + 1)
 await frames(2)
 victim.receive_hit(5000, "bullet")
 await frames(12)
 check(game.state.equipment.size() == 3 and game.state.gear_drops.is_empty(), "actual elite kill drops a unique item that proximity pickup collects")
 await frames(8)
 check(game.state.equipment.size() == 3, "gear pickup cannot duplicate inventory")
 game.state.bones = 1
 game.state.supplies.scrap = 1
 var ammunition: int = game.state.supplies.light_ammo
 check("制成" in game.state.craft_ammo("light_ammo") and game.state.supplies.light_ammo == ammunition + 12 and game.state.bones == 0 and game.state.supplies.scrap == 0, "ammo recipe conserves ingredients and output")
 while game.state.equipment.size() < 20: game.state.grant_gear("sword")
 victim = fixture("brute", Vector2(515, 350))
 victim.record.elite = true
 while true:
  var probe := FarmState.new()
  probe.day = game.state.day
  probe.reward_enemy(victim.record, victim.position)
  if not probe.gear_drops.is_empty(): break
  victim.record.id += 1000
 game.state.next_id = maxi(game.state.next_id, victim.record.id + 1)
 await frames(2)
 victim.receive_hit(5000, "bullet")
 await frames(12)
 check(game.state.equipment.size() == 20 and game.state.gear_drops.size() == 1, "full equipment inventory leaves dropped item on map")
 game.state.equipment.pop_back()
 await frames(25)
 check(game.state.equipment.size() == 20 and game.state.gear_drops.is_empty(), "freeing an equipment slot permits later pickup")
 reset_world(Vector2(480, 350))
 var wearable: Dictionary = game.state.grant_gear("smg", 2, 2)
 await key(KEY_B)
 check(game.modal != null, "equipment key opens actual UI")
 var chosen: Button = null
 for button in buttons(game.modal):
  if button.text.begins_with(YinBalance.gear_name(wearable)): chosen = button
 var found_button: bool = chosen != null
 if found_button: await click_button(chosen)
 check(found_button and game.state.equipped_gear == wearable.id and game.player.held_item == "smg", "equipment button equips the displayed gun")
 game.close_modal()
 game.travel("graveyard")
 await frames(3)
 game.player.position = Vector2(810, 535)
 await key(KEY_E)
 check(game.state.zone == "forest", "cemetery gate keyboard interaction enters expanded forest")
 var origin: float = game.player.position.x
 Input.action_press("move_right")
 await frames(25)
 Input.action_release("move_right")
 check(game.player.position.x > origin + 70, "physical movement works in expanded forest")
 game.player.position = Vector2(1400, 900)
 await frames(40)
 var camera: Camera2D = game.player.get_node("Camera2D")
 check(camera.get_screen_center_position().x > 1000 and game.world.is_safe_position(game.player.position), "camera follows traversable terrain beyond original map width")
 game.player.position = Vector2(180, 1120)
 await key(KEY_E)
 check(game.state.zone == "graveyard" and game.player.position.distance_to(Vector2(810, 535)) < 5, "forest return gate restores named cemetery entry")
 print("Arsenal and barrage: ", checks, " checks, ", failures, " failures")
 game.queue_free()
 await frames(3)
 quit(1 if failures else 0)
