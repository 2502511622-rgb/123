class_name YinDialoguePanel
extends VBoxContainer
signal finished
var data: YinDialogueData
var index: int = 0
var text_label: RichTextLabel
var progress: Label
var elapsed: float = 0
func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	add_child(row)
	if data.portrait != null:
		var image := TextureRect.new()
		image.texture = data.portrait
		image.custom_minimum_size = Vector2(32, 44)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(image)
	var speaker := Label.new()
	speaker.text = data.speaker
	speaker.add_theme_color_override("font_color", Color("49624f"))
	row.add_child(speaker)
	text_label = RichTextLabel.new()
	text_label.custom_minimum_size = Vector2(404, 70)
	text_label.fit_content = true
	text_label.add_theme_font_size_override("normal_font_size", 12)
	text_label.add_theme_color_override("default_color", Color("48584b"))
	add_child(text_label)
	progress = Label.new()
	progress.add_theme_font_size_override("font_size", 10)
	progress.add_theme_color_override("font_color", Color("526653"))
	add_child(progress)
	var next := Button.new()
	next.text = "继续 / 显示整句"
	next.pressed.connect(advance)
	add_child(next)
	show_line()
func _process(delta: float) -> void:
	elapsed += delta
	text_label.visible_characters = int(elapsed * 35)
func show_line() -> void:
	if index >= data.lines.size():
		finished.emit()
		return
	elapsed = 0
	text_label.text = data.lines[index]
	text_label.visible_characters = 0
	progress.text = "%d / %d" % [index + 1, data.lines.size()]
func advance() -> void:
	if index >= data.lines.size(): return
	if text_label.visible_characters >= 0 and text_label.visible_characters < text_label.get_total_character_count():
		elapsed = 10000
		text_label.visible_characters = -1
	else:
		index += 1
		show_line()
