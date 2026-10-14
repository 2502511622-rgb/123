class_name YinActionState
extends RefCounted
# Original implementation of a timed action, shared by tools and sword/spells.
var kind: String
var duration: float
var remaining: float = 0
var committed: bool = false
var commit: Callable
func _init(action_kind: String, seconds: float, effect: Callable) -> void:
	kind = action_kind
	duration = seconds
	remaining = seconds
	commit = effect
func enter() -> void:
	if not committed:
		committed = true
		if commit.is_valid(): commit.call()
func tick(delta: float) -> bool:
	remaining = maxf(0, remaining - delta)
	return remaining <= 0
