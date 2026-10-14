class_name YinSaveComponent
extends Node
const SaveStore = preload("res://scripts/save_store.gd")
var state: FarmState
var capture_pose: Callable
func load_game() -> bool:
	return SaveStore.load_game(state) if state != null else false
func save_game() -> bool:
	if state == null: return false
	if capture_pose.is_valid(): capture_pose.call()
	return SaveStore.save_game(state)
