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

static func existing_path() -> String:
	if FileAccess.file_exists(PATH):return PATH
	var legacy: String=OS.get_user_data_dir().get_base_dir().path_join("阴田录").path_join("yintian-save.json")
	return legacy if FileAccess.file_exists(legacy) else PATH

static func has_save() -> bool:
	return FileAccess.file_exists(existing_path())

static func load_game(state: FarmState) -> bool:
	var source: String=existing_path()
	if not FileAccess.file_exists(source):
		return true
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null:
		return false
	var data: Variant = JSON.parse_string(file.get_as_text())
	return state.restore(data) if data is Dictionary else false
