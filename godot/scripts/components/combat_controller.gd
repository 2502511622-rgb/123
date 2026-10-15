class_name YinCombatController
extends Node
const ARSENAL = {
	"sword": preload("res://resources/weapons/sword.tres"),
	"seal": preload("res://resources/weapons/seal.tres"),
	"fire": preload("res://resources/weapons/fire.tres")
}
const TOOL_ATTACKS = {"tool0": [10, 42.0, 0.3, 0.45], "tool3": [12, 53.0, 0.25, 0.38], "tool4": [24, 44.0, 0.4, 0.6], "tool5": [18, 45.0, 0.35, 0.52]}
var game: Node2D
var pending: Dictionary = {}
var reload_job: Dictionary = {}
var random := RandomNumberGenerator.new()
var spin_time: float = 0
func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or game.modal != null: return
	game.state.update_combat(delta)
	if game.player.held_item == "gatling" and (Input.is_action_pressed("attack") or game.shooting_mouse): spin_time = minf(1, spin_time + delta)
	else: spin_time = 0
	if not reload_job.is_empty():
		if not is_instance_valid(reload_job.actor) or reload_job.actor != game.player or reload_job.id != game.state.equipped_gear:
			reload_job.clear()
		else:
			reload_job.remaining -= delta
			if reload_job.remaining <= 0:
				var gear: Dictionary = game.state.current_gear()
				var spec: Dictionary = YinBalance.WEAPONS[gear.weapon]
				var amount: int = mini(spec.magazine - int(gear.magazine), game.state.container_count("bag", spec.ammo))
				gear.magazine += amount
				game.state.set_container_count("bag", spec.ammo, game.state.container_count("bag", spec.ammo) - amount)
				reload_job.clear()
				game.notify_action("装填完成。")
	if pending.is_empty(): return
	if not is_instance_valid(pending.actor) or pending.actor != game.player:
		pending.clear()
		return
	if game.modal != null: return
	pending.delay -= delta
	if pending.delay > 0: return
	var strike: Dictionary = pending.duplicate()
	pending.clear()
	for target in game.player.hitbox.targets(strike.facing):
		target.receive_hit(strike.damage, strike.get("method", "sword"))
		if is_instance_valid(target): apply_payload(target, strike.get("payload", {}))
	game.persist()
func visible(target: YinEnemy) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(game.player.global_position + Vector2(0, -4), target.global_position + Vector2(0, -4), 1)
	return game.player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
func spell_target(reach: float) -> YinEnemy:
	var chosen: YinEnemy = null
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or node.is_queued_for_deletion() or node.record.dead or node.get_parent() != game.world.actors: continue
		var distance: float = game.player.position.distance_to(node.position)
		if distance < reach and visible(node):
			chosen = node
			reach = distance
	return chosen
func trigger(method: String) -> bool:
	if game.player.frozen or not reload_job.is_empty(): return false
	if method == "sword" and game.player.held_item in YinBalance.GUNS: return shoot()
	if method == "sword" and game.player.held_item in YinBalance.MAGIC: return cast_weapon()
	if game.action_cooldown > 0 or not ARSENAL.has(method): return false
	var spec: YinWeaponSpec = ARSENAL[method]
	var using_tool: bool = method == "sword" and game.player.held_item.begins_with("tool")
	if using_tool:
		if not TOOL_ATTACKS.has(game.player.held_item):
			game.refresh("阴种与水壶用于经营；7 选择桃木剑，8/9/0 选择枪械。")
			return false
		var values: Array = TOOL_ATTACKS[game.player.held_item]
		spec = YinWeaponSpec.new()
		spec.damage = values[0]
		spec.reach = values[1]
		spec.action_time = values[2]
		spec.recovery = values[3]
	if method == "sword" and not using_tool:
		var weapon: Dictionary = YinBalance.WEAPONS[game.state.current_gear().weapon]
		spec = YinWeaponSpec.new()
		spec.damage = weapon.damage
		spec.reach = weapon.range
		spec.action_time = 0.22 if game.player.held_item != "whip" else 0.3
		spec.recovery = weapon.interval
	if method == "sword":
		if not game.player.state_machine.begin("attack", spec.action_time): return false
		game.player.attack_time = spec.action_time
		game.action_cooldown = spec.recovery
		game.player.hitbox.radius = spec.reach
		var rolled: Dictionary = roll_hit(spec.damage, {} if using_tool else game.state.current_gear())
		pending = {"payload": rolled, "actor": game.player, "facing": game.player.facing, "damage": rolled.damage, "delay": 0.06, "method": "tool" if using_tool else "sword"}
	else:
		var target: YinEnemy = spell_target(spec.reach)
		if target == null:
			game.refresh("符术范围内没有目标。")
			return false
		if game.state.skill_ranks[method] < 1:
			game.refresh("尚未学习技能：I → 技能树。")
			return false
		if game.state.energy < YinAbilities.SKILLS[method].cost or game.state.skill_charges[method] < 1:
			game.refresh("体力或充能不足，调息并等待自动充能。")
			return false
		if not game.player.state_machine.begin("spell", spec.action_time): return false
		game.state.spend_skill(method)
		game.action_cooldown = spec.recovery
		game.world.spell_trace(game.player.position + Vector2(0, -20), target.position + Vector2(0, -20), method)
		target.receive_hit(spec.damage + 5 * (int(game.state.skill_ranks[method]) - 1), method)
		game.refresh("符火伤骸：完整度下降 35。" if method == "fire" else "镇符压制 3 秒，完整度保留。")
	game.persist()
	return true

func shoot() -> bool:
	if game.modal != null or game.player.frozen or game.action_cooldown > 0 or not reload_job.is_empty(): return false
	if game.player.state_machine.current not in ["idle", "walk"]: return false
	var gear: Dictionary = game.state.current_gear()
	if gear.weapon not in YinBalance.GUNS or game.player.held_item != gear.weapon: return false
	var spec: Dictionary = YinBalance.WEAPONS[gear.weapon]
	if gear.weapon == "gatling" and spin_time < 0.25: return false
	if gear.magazine <= 0:
		reload()
		return false
	var aim: Vector2 = game.player.aim_direction.normalized()
	if aim == Vector2.ZERO: aim = game.player.facing
	var direction: Vector2 = aim.rotated(random.randf_range(-spec.spread, spec.spread))
	var start: Vector2 = game.player.position + Vector2(0, -4)
	var rolled: Dictionary = roll_hit(spec.damage, gear)
	if not game.world.projectiles.spawn(start, direction, true, rolled.damage, spec.speed, spec.range, YinBalance.ELEMENT_COLORS.get(rolled.element, Color("f1d599")), rolled): return false
	gear.magazine -= 1
	game.action_cooldown += spec.interval
	game.player.recoil_time = 0.09
	game.player.facing = aim
	game.player.aim_direction = aim
	game.world.effect(start + aim * 18 - Vector2(0, 14), Color("f2d08e"))
	game.persist()
	return true
func reload() -> bool:
	if game.modal != null or not reload_job.is_empty(): return false
	var gear: Dictionary = game.state.current_gear()
	var spec: Dictionary = YinBalance.WEAPONS[gear.weapon]
	if spec.ammo == "" or game.player.held_item != gear.weapon or gear.magazine >= spec.magazine: return false
	if game.state.container_count("bag", spec.ammo) <= 0:
		game.refresh("备用弹药耗尽：杂货铺购买，或案台用零件与骨料制作。")
		return false
	if not game.player.state_machine.begin("reload", spec.reload): return false
	reload_job = {"id": gear.id, "actor": game.player, "remaining": spec.reload}
	game.refresh("正在装填 %s，%.1f 秒。" % [spec.name, spec.reload])
	return true
func select_weapon(kind: String) -> bool:
	var selected: Dictionary = {}
	for gear in game.state.equipment:
		if gear.weapon != kind: continue
		if selected.is_empty() or gear.tier * 10 + gear.bonus > selected.tier * 10 + selected.bonus: selected = gear
	if selected.is_empty():
		game.refresh("尚无%s：杂货铺购入，或击杀精英获取装备。" % YinBalance.WEAPONS[kind].name)
		return false
	cancel_reload()
	game.state.equip(selected.id)
	game.player.held_item = kind
	game.notify_action("手持 " + YinBalance.gear_name(selected) + "。J 或左键攻击，U 装填。")
	return true
func cancel_reload() -> void:
	if not reload_job.is_empty():
		reload_job.clear()
		game.player.state_machine.reset()

func roll_hit(base: int, gear: Dictionary) -> Dictionary:
	var damage: int = YinBalance.damage(base, YinBalance.level(game.state.cultivation), gear)
	var bleed: int = 0
	var critical: bool = false
	for affix in gear.get("affixes", []):
		if affix.id == "crit" and random.randf() < float(affix.value) / 100:
			damage = roundi(damage * 1.65)
			critical = true
		if affix.id == "bleed" and random.randf() < 0.25: bleed = int(affix.value)
	return {"damage": damage, "bleed": bleed, "critical": critical, "element": gear.get("enchantment", "") if random.randf() < 0.3 else "", "power": 3 + int(gear.get("quality", 0))}

func apply_payload(target: YinEnemy, payload: Dictionary) -> void:
	if not is_instance_valid(target) or target.record.dead or target.is_queued_for_deletion(): return
	if payload.get("bleed", 0) > 0: target.apply_bleed(payload.bleed, 2)
	var element: String = payload.get("element", "")
	if element != "": target.apply_element(element, int(payload.get("power", 3)))

func cast_weapon() -> bool:
	if game.modal != null or game.player.frozen or game.action_cooldown > 0 or not reload_job.is_empty(): return false
	var gear: Dictionary = game.state.current_gear()
	if gear.weapon not in YinBalance.MAGIC or game.player.held_item != gear.weapon: return false
	var spec: Dictionary = YinBalance.WEAPONS[gear.weapon]
	if game.state.energy < spec.energy:
		game.refresh("气力不足，调息后再施术。")
		return false
	var target: YinEnemy = spell_target(spec.range) if gear.weapon == "curse_doll" else null
	if gear.weapon == "curse_doll" and target == null: return false
	if not game.player.state_machine.begin("spell", 0.22): return false
	var payload: Dictionary = roll_hit(spec.damage, gear)
	var element: String = gear.get("enchantment", "")
	var tint: Color = YinBalance.ELEMENT_COLORS.get(element, Color("bba1df"))
	if gear.weapon == "spellbook":
		var direction: Vector2 = game.player.aim_direction.normalized()
		if direction == Vector2.ZERO: direction = game.player.facing
		if not game.world.projectiles.spawn(game.player.position + Vector2(0, -4), direction, true, payload.damage, spec.speed, spec.range, tint, payload):
			game.player.state_machine.reset()
			return false
	else:
		game.world.spell_trace(game.player.position + Vector2(0, -20), target.position + Vector2(0, -20), "curse")
		target.receive_hit(payload.damage, "curse")
		target.apply_bleed(4, 3)
		apply_payload(target, payload)
	game.state.energy -= spec.energy
	game.action_cooldown = spec.interval
	game.player.attack_time = 0.22
	game.persist()
	return true
