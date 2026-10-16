extends Control
const SaveStore = preload("res://scripts/save_store.gd")
var hint: Label
var confirmation: ConfirmationDialog
var existing_valid: bool = false
func _ready() -> void:
	YinDisplaySettings.load_settings()
	theme = YinPixelTheme.install()
	ThemeDB.fallback_font = preload("res://assets/mossfield-font.ttf")
	var title := Label.new()
	title.text = "阴 田 录"
	title.position = Vector2(48, 50)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("d4cfad"))
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "缝合异境 · 巡夜者之旅"
	subtitle.position = Vector2(50, 104)
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("99ad9a"))
	add_child(subtitle)
	var saved := FarmState.new()
	existing_valid = FileAccess.file_exists(SaveStore.PATH) and SaveStore.load_game(saved)
	var start := make_button("新建义庄", Vector2(48, 160))
	start.pressed.connect(func():
		if FileAccess.file_exists(SaveStore.PATH): confirmation.popup_centered()
		else: new_game()
	)
	var continue_button := make_button("继续 · 第 %d 日" % saved.day if existing_valid else "继续 · 尚无有效存档", Vector2(48, 203))
	continue_button.disabled = not existing_valid
	continue_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	var exit := make_button("退出", Vector2(48, 246))
	exit.pressed.connect(func(): get_tree().quit())
	var settings := make_button("画面设置", Vector2(216, 246))
	settings.pressed.connect(func():
		var dialog := AcceptDialog.new()
		dialog.title = "分辨率与像素显示"
		add_child(dialog)
		dialog.add_child(YinDisplaySettings.panel())
		dialog.popup_centered(Vector2i(440, 190))
		dialog.confirmed.connect(dialog.queue_free)
	)
	hint = Label.new()
	hint.text = "寻访异境。斩鬼拾装。守住人间。"
	hint.position = Vector2(48, 307)
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
	draw_rect(Rect2(0, 0, 640, 360), Color("18212f"))
	# A vignette built from real game assets, not a painted gameplay mockup.
	for i in range(5):
		var shade := Color("354858")
		shade.a = 0.7 - i * 0.1
		draw_colored_polygon(PackedVector2Array([Vector2(300, 200 + i * 16), Vector2(410, 115 + i * 18), Vector2(480, 144 + i * 10), Vector2(570, 90 + i * 16), Vector2(640, 130 + i * 20), Vector2(640, 360), Vector2(300, 360)]), shade)
	draw_circle(Vector2(515, 68), 25, Color("c3c4a0"))
	draw_circle(Vector2(525, 61), 23, Color("18212f"))
	for x in [348, 390, 566, 610]: draw_texture(YinArt.texture("tree"), Vector2(x, 100 + x % 37), Color("738c7a"))
	draw_texture(YinArt.texture("cottage"), Vector2(390, 174))
	draw_texture(YinArt.texture("lantern"), Vector2(372, 258))
	draw_texture(YinArt.texture("tree"), Vector2(558, 235))
	for i in range(3): draw_rect(Rect2(300, 285 + i * 20, 340, 7), Color(0.5, 0.66, 0.60, 0.035))
	draw_rect(Rect2(24, 24, 592, 312), Color("748065"), false, 1)
	draw_line(Vector2(48, 132), Vector2(210, 132), Color("b49c68"), 1)
	for at in [Vector2(24, 24), Vector2(608, 24), Vector2(24, 328), Vector2(608, 328)]: draw_rect(Rect2(at, Vector2(8, 8)), Color("bda56f"), false, 1)
