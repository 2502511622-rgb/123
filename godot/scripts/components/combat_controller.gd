class_name YinCombatController
extends Node
const ARSENAL = {
	"sword": preload("res://resources/weapons/sword.tres"),
	"seal": preload("res://resources/weapons/seal.tres"),
	"fire": preload("res://resources/weapons/fire.tres")
}
var game: Node2D
var pending: Dictionary = {}
func _physics_process(delta: float) -> void:
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
		target.receive_hit(strike.damage, "sword")
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
	if game.action_cooldown > 0 or not ARSENAL.has(method): return false
	var spec: YinWeaponSpec = ARSENAL[method]
	if method == "sword":
		if not game.player.state_machine.begin("attack", spec.action_time): return false
		game.player.attack_time = spec.action_time
		game.action_cooldown = spec.recovery
		game.player.hitbox.radius = spec.reach
		pending = {"actor": game.player, "facing": game.player.facing, "damage": spec.damage + int(game.state.cultivation / 40), "delay": 0.06}
	else:
		var target: YinEnemy = spell_target(spec.reach)
		if target == null:
			game.refresh("符术范围内没有目标。")
			return false
		if game.state.talismans < spec.talisman_cost:
			game.refresh("符箓不足，回义庄制作。")
			return false
		if not game.player.state_machine.begin("spell", spec.action_time): return false
		game.state.talismans -= spec.talisman_cost
		game.action_cooldown = spec.recovery
		game.world.spell_trace(game.player.position + Vector2(0, -20), target.position + Vector2(0, -20), method)
		target.receive_hit(spec.damage, method)
		game.refresh("符火伤骸：完整度下降 35。" if method == "fire" else "镇符压制 3 秒，完整度保留。")
	game.persist()
	return true
