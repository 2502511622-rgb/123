class_name YinCombatController
extends Node
const ARSENAL = {
	"sword": preload("res://resources/weapons/sword.tres"),
	"seal": preload("res://resources/weapons/seal.tres"),
	"fire": preload("res://resources/weapons/fire.tres")
}
var game: Node2D
func trigger(method: String) -> bool:
	if game.action_cooldown > 0 or not ARSENAL.has(method): return false
	var spec: YinWeaponSpec = ARSENAL[method]
	if method == "sword":
		if not game.player.state_machine.begin("attack", spec.action_time): return false
		game.player.attack_time = 0.18
		game.action_cooldown = spec.recovery
		game.player.hitbox.radius = spec.reach
		for target in game.player.hitbox.targets(game.player.facing):
			target.receive_hit(spec.damage + int(game.state.cultivation / 40), method)
	else:
		var target: YinEnemy = game.nearest_enemy(game.player.position, spec.reach)
		if target == null:
			game.refresh("符术范围内没有目标。")
			return false
		if game.state.talismans < spec.talisman_cost:
			game.refresh("符箓不足，回义庄制作。")
			return false
		if not game.player.state_machine.begin("spell", spec.action_time): return false
		game.state.talismans -= spec.talisman_cost
		game.action_cooldown = spec.recovery
		target.receive_hit(spec.damage, method)
		game.refresh("符火伤骸：完整度下降 35。" if method == "fire" else "镇符压制 3 秒，完整度保留。")
	game.persist()
	return true
