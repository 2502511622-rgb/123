extends Control
const SaveStore = preload("res://scripts/save_store.gd")
var hint: Label
var confirmation: ConfirmationDialog
var existing_valid: bool = false
func _ready() -> void:
	theme = YinPixelTheme.install()
	ThemeDB.fallback_font = preload("res://assets/mossfield-font.ttf")
	var title := Label.new()
	title.text = "阴 田 录"
	title.position = Vector2(225, 48)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("d4cfad"))
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "槐阴村 · 十日祭帖"
	subtitle.position = Vector2(242, 102)
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("99ad9a"))
	add_child(subtitle)
	var saved := FarmState.new()
	existing_valid = FileAccess.file_exists(SaveStore.PATH) and SaveStore.load_game(saved)
	var start := make_button("新建义庄", Vector2(242, 161))
	start.pressed.connect(func():
		if FileAccess.file_exists(SaveStore.PATH): confirmation.popup_centered()
		else: new_game()
	)
	var continue_button := make_button("继续 · 第 %d 日" % saved.day if existing_valid else "继续 · 尚无有效存档", Vector2(242, 204))
	continue_button.disabled = not existing_valid
	continue_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	var exit := make_button("退出", Vector2(242, 247))
	exit.pressed.connect(func(): get_tree().quit())
	hint = Label.new()
	hint.text = "种田谋生。杀鬼留骸。每夜点名。"
	hint.position = Vector2(194, 304)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color("91a28f"))
	add_child(hint)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "开始新的十日祭帖"
	confirmation.dialog_text = "现有进度会备份，然后开始新的义庄。是否继续？"
	confirmation.confirmed.connect(new_game)
	add_child(confirmation)
func make_button(text: String, at: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = Vector2(156, 32)
	button.add_theme_stylebox_override("normal", YinPixelTheme.box())
	button.add_theme_font_size_override("font_size", 13)
	add_child(button)
	return button
func new_game() -> void:
	if FileAccess.file_exists(SaveStore.PATH):
		var result: int = DirAccess.copy_absolute(SaveStore.PATH, SaveStore.PATH + ".backup-" + str(Time.get_unix_time_from_system()))
		if result != OK:
			hint.text = "无法备份原存档，未覆盖进度。"
			return
	if SaveStore.save_game(FarmState.new()): get_tree().change_scene_to_file("res://scenes/main.tscn")
	else: hint.text = "无法写入存档，请检查用户数据目录。"
func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("263d3d"))
	var trees: Texture2D = preload("res://assets/tree.png")
	for x in [-12, 25, 546, 584]: draw_texture_rect(trees, Rect2(x, 110, 64, 92), false, Color("839786"))
	draw_texture_rect(preload("res://assets/cottage.png"), Rect2(56, 177, 144, 122), false, Color("8b9b8d"))
	draw_texture_rect(preload("res://assets/lantern.png"), Rect2(488, 198, 32, 48), false)
	draw_rect(Rect2(8, 8, 624, 344), Color("657767"), false, 1)
	for at in [Vector2(8, 8), Vector2(620, 8), Vector2(8, 340), Vector2(620, 340)]:
		draw_rect(Rect2(at, Vector2(12, 12)), Color("c6ac78"), false, 2)
	# Stepped moon and small stars keep the scene on the pixel grid.
	draw_rect(Rect2(504, 51, 24, 36), Color("afbaa2"))
	draw_rect(Rect2(498, 57, 36, 24), Color("afbaa2"))
	draw_rect(Rect2(502, 60, 8, 4), Color("8da18e"))
	for at in [Vector2(85, 53), Vector2(136, 90), Vector2(466, 31), Vector2(574, 104)]:
		draw_rect(Rect2(at, Vector2(2, 2)), Color("9cac98"))
	for x in range(16, 626, 8):
		draw_rect(Rect2(x, 348, 4, 2), Color("596e60"))
