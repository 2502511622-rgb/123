extends SceneTree
var checks := 0
var failures := 0
var game: Node2D
var started: int = Time.get_ticks_msec()
func _process(_delta: float) -> bool:
 if Time.get_ticks_msec() - started > 55000:
  push_error("Campaign playthrough timed out")
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
func screenshot(name: String) -> void:
 if DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().is_empty(): return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/" + name + ".png")
func wheel(direction: int) -> void:
 var event := InputEventMouseButton.new()
 event.position = Vector2(320, 180)
 event.button_index = MOUSE_BUTTON_WHEEL_DOWN if direction > 0 else MOUSE_BUTTON_WHEEL_UP
 event.pressed = true
 Input.parse_input_event(event)
 Input.flush_buffered_events()
 await frames(3)
func fight(limit: int, boss_fight: bool = false) -> bool:
 for i in range(limit):
  var target: YinEnemy = game.combat.spell_target(1000)
  if target == null: target = game.nearest_enemy(game.player.position, 1000)
  if target == null:
   Input.action_release("attack")
   release_movement()
   return true
  if game.state.zone != ("farm" if boss_fight else "village"):
   Input.action_release("attack")
   release_movement()
   return false
  game.player.aim_direction = game.player.position.direction_to(target.position)
  release_movement()
  if boss_fight:
   Input.action_press("move_right" if game.player.position.x < 510 and i % 160 < 80 else "move_left")
   if game.player.position.x < 365: Input.action_release("move_left"); Input.action_press("move_right")
  elif game.player.position.distance_to(target.position) < 140:
   var away: Vector2 = target.position.direction_to(game.player.position)
   if absf(away.x) > 0.3: Input.action_press("move_right" if away.x > 0 else "move_left")
   if absf(away.y) > 0.3: Input.action_press("move_down" if away.y > 0 else "move_up")
  elif game.player.position.distance_to(target.position) > 260:
   var toward: Vector2 = game.player.position.direction_to(target.position)
   if absf(toward.x) > 0.3: Input.action_press("move_right" if toward.x > 0 else "move_left")
   if absf(toward.y) > 0.3: Input.action_press("move_down" if toward.y > 0 else "move_up")
  Input.action_press("attack")
  if i % 90 == 0: await key(KEY_SHIFT)
  if i == 40 and game.combat.spell_target(145) != null: await key(KEY_G)
  await physics_frame
 Input.action_release("attack")
 release_movement()
 return game.nearest_enemy(game.player.position, 2000) == null
func run() -> void:
 Engine.time_scale = 3
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await frames(4)
 game.close_modal()
 # Scenario A: an armed level-two character reaches day three after farming.
 game.state = FarmState.new()
 game.state.intro_seen = true
 game.state.next_day()
 game.state.next_day()
 game.state.cultivation = 80
 game.state.money = 300
 game.state.oil = 24
 game.state.bones = 8
 game.state.supplies.rifle_ammo = 24
 game.build_zone("farm", Vector2(810, 350))
 await frames(4)
 await key(KEY_K)
 check(game.character_tab == "书信" and game.modal != null and game.state.letters[0].read, "player opens and reads third-day rescue letter")
 await screenshot("mail")
 await key(KEY_ESCAPE)
 check(await walk(Vector2(860, 350)), "walks to village gate")
 await key(KEY_E)
 check(game.state.zone == "village" and get_nodes_in_group("villagers").size() == 6, "village gate enters living settlement with six villagers")
 check(await walk(Vector2(180, 700)) and await walk(Vector2(970, 700)) and await walk(Vector2(970, 335)) and await walk(Vector2(860, 335)), "player navigates village streets without house collisions")
 await key(KEY_E)
 check(game.modal != null and await choose("铁匠交易"), "talks to blacksmith and opens actual shop")
 var money_before: int = game.state.money
 check(await choose("步枪 ·") and game.state.money == money_before - 140, "buys rifle through shop GUI")
 var ammo_before: int = game.state.supplies.rifle_ammo
 check(await choose("步枪弹 ×12") and game.state.supplies.rifle_ammo == ammo_before + 12, "buys ammunition through shop GUI")
 await key(KEY_ESCAPE)
 await key(KEY_B)
 check(await choose("步枪 T1") and game.state.current_gear().weapon == "rifle", "equips rifle into primary loadout through GUI")
 await key(KEY_ESCAPE)
 var smart: bool = game.state.smart_farming
 await wheel(1)
 check(game.player.held_item == "pistol", "wheel changes primary to secondary")
 await wheel(1)
 check(game.player.held_item == "sword", "wheel changes secondary to melee")
 await wheel(1)
 check(game.player.held_item == "rifle" and game.state.smart_farming == smart, "wheel returns to primary without switching farm tools")
 await key(KEY_I)
 check(await choose("技能") and await choose("学习 / 升阶 符火"), "learns fire in skill tree by mouse")
 check(game.state.skill_ranks.fire == 1 and game.state.skill_points() == 0, "learning consumes one real skill point")
 await screenshot("skill-tree")
 await key(KEY_ESCAPE)
 await key(KEY_U)
 await frames(110)
 check(game.state.current_gear().magazine == 12, "reloads newly bought rifle from owned ammo")
 check(await walk(Vector2(970, 335)) and await walk(Vector2(970, 700)) and await walk(Vector2(180, 700)) and await walk(Vector2(180, 800)), "walks back through village to farm exit")
 await key(KEY_E)
 await key(KEY_T)
 check(await choose("等到入夜"), "waits for evening using normal in-game control")
 await frames(4)
 check(game.state.raid_status == "active" and game.state.enemies.filter(func(e): return e.zone == "village" and not e.dead).size() == 4, "rescue night starts a single actual monster wave")
 await key(KEY_E)
 check(game.state.zone == "village", "answers rescue by re-entering village")
 check(await walk(Vector2(180, 760)) and await walk(Vector2(970, 760)) and await walk(Vector2(970, 660)), "reaches attacked village plaza through physical movement")
 await screenshot("village-raid")
 check(game.state.villagers.any(func(v): return v.hp < 100), "real monsters damage real villager health")
 var talismans: int = game.state.talismans
 var fired: bool = await fight(1000)
 await frames(4)
 check(fired and game.state.raid_status == "success" and game.state.health > 0, "aims, shoots, reloads and dodges to complete actual rescue")
 check(game.state.talismans == talismans, "combat skill uses no talisman materials")
 var corpses: Array = game.state.remains.filter(func(r): return r.zone == "village" and r.integrity >= 60)
 corpses.sort_custom(func(a, b): return game.player.position.distance_to(Vector2(a.at[0], a.at[1])) < game.player.position.distance_to(Vector2(b.at[0], b.at[1])))
 if not corpses.is_empty():
  var corpse: Dictionary = corpses[0]
  check(await walk(Vector2(corpse.at[0], corpse.at[1])), "physically walks onto slain monster corpse")
  await key(KEY_V)
 check(game.state.spirits.size() == 1 and game.state.spirits[0].hp > 0, "V refines corpse into follower with independent health")
 if game.state.spirits.is_empty(): quit(1); return
 await key(KEY_H)
 check(game.character_tab == "随从" and await choose("训练升级"), "opens follower manager and trains through GUI")
 check(game.state.spirits[0].level == 2, "trained follower levels up and retains source abilities")
 await screenshot("companions")
 check(await choose("解散") and await choose("确认解散"), "confirms dismissal through follower UI")
 check(game.state.spirits.is_empty() and get_nodes_in_group("companions").all(func(c): return c.is_queued_for_deletion()), "dismissed follower leaves roster and world")
 await key(KEY_ESCAPE)
 # Scenario B: separate prepared level-four equipment, full-health story boss.
 game.state = FarmState.new()
 game.state.intro_seen = true
 game.state.cultivation = 240
 game.state.skill_ranks.fire = 1
 game.state.day = 9
 game.state.minutes = 1080
 game.state.oil = 20
 game.state.bones = 8
 game.state.supplies.rifle_ammo = 72
 game.state.supplies.scrap = 4
 var rifle: Dictionary = game.state.grant_gear("rifle", 2, 1)
 rifle.magazine = 12
 game.state.equip(rifle.id)
 game.build_zone("farm", Vector2(440, 540))
 game.player.held_item = "rifle"
 await frames(4)
 check(game.has_live_boss() and game.state.enemies.any(func(e): return e.kind == "boss" and e.max_hp >= 520), "full strengthened boss enters real farm scene")
 var success: bool = await fight(1500, true)
 await frames(4)
 check(success and game.state.boss_defeated and game.state.health > 0, "player defeats full-strength boss through shooting, movement and dodging")
 var boss_remains: Array = game.state.remains.filter(func(r): return r.kind == "boss")
 if not boss_remains.is_empty():
  var corpse: Dictionary = boss_remains[0]
  check(await walk(Vector2(corpse.at[0], corpse.at[1])), "walks onto boss remains")
  await key(KEY_V)
 check(game.state.spirits.size() == 1 and game.state.spirits[0].source_kind == "boss" and game.state.deployment_used() == 2, "boss can be refined with inherited active and passive skills")
 await frames(4)
 var follower: CharacterBody2D = get_nodes_in_group("companions")[0]
 var life: int = follower.record.hp
 game.world.projectiles.spawn(follower.position - Vector2(26, 0), Vector2.RIGHT, false, 12, 400, 100, Color("c77881"))
 await frames(12)
 check(follower.record.hp < life, "hostile projectile hits actual follower hurtbox")
 var target_record: Dictionary = game.state.spawn_record("bone", "farm", follower.position + Vector2(100, 0), 1)
 game.spawn_enemies()
 follower.skill_cooldown = 0
 await frames(6)
 check(game.world.projectiles.bullets.any(func(b): return b.friendly), "refined boss actually uses inherited radial skill")
 follower.receive_hit(1000)
 await frames(2)
 check(game.state.spirits[0].hp == 0 and not game.state.spirits[0].active, "follower can be defeated and recalled instead of being immortal")
 await key(KEY_H)
 check(await choose("疗养") and game.state.spirits[0].hp == game.state.spirits[0].max_hp, "heals fallen follower in management panel")
 check(await choose("出战") and game.state.spirits[0].active, "redeploys recovered follower without duplicating actor")
 await key(KEY_ESCAPE)
 # Scenario C: controlled target for weapon affix and DOT verification.
 for actor in get_nodes_in_group("enemies"): actor.queue_free()
 for enemy in game.state.enemies: enemy.dead = true
 game.state.spirits[0].active = false
 game.spawn_spirits()
 await frames(3)
 var gear: Dictionary = game.state.current_gear()
 await key(KEY_B)
 check(await choose("铭刻词条 · " + YinBalance.gear_name(gear)) and await choose("铭刻暴击") and await choose("铭刻重伤"), "adds both weapon affixes through actual inscription UI")
 await key(KEY_ESCAPE)
 game.combat.random.seed = 123
 var crit_rolls: int = 0
 var bleed_rolls: int = 0
 for i in range(1000):
  var rolled: Dictionary = game.combat.roll_hit(31, gear)
  if rolled.critical: crit_rolls += 1
  if rolled.bleed > 0: bleed_rolls += 1
 check(crit_rolls > 70 and crit_rolls < 170, "critical affix changes actual hit rolls at bounded probability")
 check(bleed_rolls > 180 and bleed_rolls < 320, "heavy-wound affix rolls actual timed injury")
 target_record = game.state.spawn_record("bone", "farm", game.player.position + Vector2(55, 0), 1)
 target_record.hp = 2000
 target_record.max_hp = 2000
 target_record.armor = 0
 game.spawn_enemies()
 await frames(3)
 var dummy: YinEnemy = game.nearest_enemy(game.player.position, 80)
 dummy.stun = 100
 game.player.aim_direction = Vector2.RIGHT
 gear.magazine = 12
 game.combat.cancel_reload()
 game.action_cooldown = 0
 game.combat.random.seed = 0
 var critical_seen: bool = false
 var wound_seen: bool = false
 for i in range(10):
  var before_hit: int = target_record.hp
  await key(KEY_J)
  await frames(20)
  critical_seen = critical_seen or before_hit - int(target_record.hp) > 50
  wound_seen = wound_seen or dummy.bleed_time > 0
 check(critical_seen, "fired bullets apply real critical damage")
 check(wound_seen, "fired bullets apply real heavy-wound status")
 var before_dot: int = target_record.hp
 if dummy.bleed_time < 1.5:
  for i in range(8):
   await key(KEY_J)
   await frames(20)
   if dummy.bleed_time > 1.5: break
 await frames(75)
 check(target_record.hp < before_dot, "injured enemy keeps losing health after player stops shooting")
 await key(KEY_B)
 check(game.modal.find_children("*", "Label", true, false).any(func(l): return "暴击 12%" in l.text and "重伤 4秒" in l.text), "equipment UI shows both rolled affixes clearly")
 for label_node in game.modal.find_children("*", "Label", true, false):
  if "暴击 12%" in label_node.text:
   var ancestor: Node = label_node.get_parent()
   while ancestor != null:
    if ancestor is ScrollContainer: ancestor.ensure_control_visible(label_node)
    ancestor = ancestor.get_parent()
 await process_frame
 await screenshot("affixes")
 await key(KEY_ESCAPE)
 var gunner: Dictionary = game.state.make_spirit("gunner", 10)
 game.state.spirits.append(gunner)
 game.spawn_spirits()
 await frames(3)
 var gunner_actor: CharacterBody2D
 for actor in get_nodes_in_group("companions"):
  if actor.record.id == gunner.id: gunner_actor = actor
 var burst_count: Array = [0]
 game.world.projectiles.projectile_spawned.connect(func(friendly):
  if friendly: burst_count[0] += 1
 )
 gunner_actor.use_inherited_skill(dummy)
 check(gunner_actor.burst_remaining == 3 and burst_count[0] == 0, "paper gunner inherits queued burst rather than unrelated fan shots")
 await frames(30)
 check(burst_count[0] == 3, "inherited burst fires three separately timed bullets")
 game.state.dismiss_spirit(gunner.id)
 game.state.spirits[0].active = true
 game.spawn_spirits()
 game.persist()
 var restored := FarmState.new()
 check(load("res://scripts/save_store.gd").load_game(restored) and restored.spirits[0].source_kind == "boss" and restored.skill_ranks.fire == 1 and restored.current_gear().weapon == "rifle" and restored.current_gear().affixes == gear.affixes, "actual save restores loadout, skill tree, health and inherited boss")
 game.queue_free()
 await frames(3)
 print("Player campaign: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
