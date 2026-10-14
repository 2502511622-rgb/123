extends RefCounted
const PATH = "user://yintian-save.json"

static func save_game(state: FarmState) -> bool:
	var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state.snapshot()))
	file.flush()
	var ok: bool = file.get_error() == OK
	file.close()
	if not ok:
		return false
	return DirAccess.rename_absolute(PATH + ".tmp", PATH) == OK

static func load_game(state: FarmState) -> bool:
	if not FileAccess.file_exists(PATH):
		return true
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return false
	var data: Variant = JSON.parse_string(file.get_as_text())
	return state.restore(data) if data is Dictionary else false
