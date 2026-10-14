extends RefCounted
const PATH = "user://farm-save.json"

static func save_game(state: FarmState) -> bool:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state.snapshot()))
	return file.get_error() == OK

static func load_game(state: FarmState) -> void:
	if not FileAccess.file_exists(PATH):
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		state.restore(data)
