class_name YinDisplaySettings
extends RefCounted
const PATH = "user://display.cfg"
const RESOLUTIONS = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)]
static func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		apply(int(config.get_value("display", "resolution", 0)), bool(config.get_value("display", "fullscreen", false)), false)
static func apply(index: int, fullscreen: bool, save: bool = true) -> void:
	index = clampi(index, 0, RESOLUTIONS.size() - 1)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		if not fullscreen:
			DisplayServer.window_set_size(RESOLUTIONS[index])
			var screen := DisplayServer.screen_get_usable_rect()
			DisplayServer.window_set_position(screen.position + (screen.size - RESOLUTIONS[index]) / 2)
	if save:
		var config := ConfigFile.new()
		config.set_value("display", "resolution", index)
		config.set_value("display", "fullscreen", fullscreen)
		config.save(PATH)
static func panel() -> VBoxContainer:
	var box := VBoxContainer.new()
	var info := Label.new()
	info.text = "整数像素缩放 · 最近邻采样 · 镜头 1:1\n屏幕不足时窗口可能超出桌面，请选适合的分辨率。"
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color("424c42"))
	box.add_child(info)
	var resolutions := OptionButton.new()
	for size_value in RESOLUTIONS: resolutions.add_item("%d × %d" % [size_value.x, size_value.y])
	var fullscreen := CheckButton.new()
	fullscreen.text = "全屏（保持整数缩放，必要时留黑边）"
	var config := ConfigFile.new()
	config.load(PATH)
	resolutions.select(clampi(int(config.get_value("display", "resolution", 0)), 0, 2))
	fullscreen.button_pressed = bool(config.get_value("display", "fullscreen", false))
	box.add_child(resolutions)
	box.add_child(fullscreen)
	var apply_button := Button.new()
	apply_button.text = "应用分辨率"
	apply_button.pressed.connect(func(): apply(resolutions.selected, fullscreen.button_pressed))
	box.add_child(apply_button)
	return box
