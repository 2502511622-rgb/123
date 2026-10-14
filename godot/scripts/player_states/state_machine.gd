class_name YinPlayerStateMachine
extends Node
signal changed(previous: String, current: String)
var current: String = "idle"
var action: YinActionState
var actor: CharacterBody2D
func bind(player: CharacterBody2D) -> void:
	actor = player
func change(next: String) -> void:
	if current == next: return
	var previous: String = current
	current = next
	changed.emit(previous, current)
func begin(kind: String, seconds: float, effect: Callable = Callable()) -> bool:
	if current in ["tool", "attack", "spell", "dodge", "paused"]: return false
	action = YinActionState.new(kind, seconds, effect)
	change(kind)
	action.enter()
	return true
func update(delta: float, direction: Vector2, paused: bool) -> Vector2:
	if paused:
		change("paused")
		return Vector2.ZERO
	if current == "paused": change("idle")
	if action != null:
		if not action.tick(delta):
			change(action.kind)
			return Vector2.ZERO if action.kind in ["tool", "attack", "spell"] else direction
		action = null
	change("walk" if direction != Vector2.ZERO else "idle")
	return direction
func reset() -> void:
	action = null
	change("idle")
