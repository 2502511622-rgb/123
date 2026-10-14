extends Control
const SaveStore = preload("res://scripts/save_store.gd")
var hint: Label
var confirmation: ConfirmationDialog
var existing_valid: bool = false
func _ready() -> void:
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color("bac2a5")
	style.border_color = Color("718574")
	style.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_color_override("font_color", Color("344a41"))
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
	draw_circle(Vector2(506, 211), 24, Color(0.9, 0.72, 0.4, 0.06))
