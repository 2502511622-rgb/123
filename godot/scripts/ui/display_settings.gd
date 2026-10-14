class_name YinDisplaySettings
extends RefCounted
const PATH = "user://display.cfg"
const RESOLUTIONS = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)]
static func embedded_run() -> bool:
	# The editor owns the size of a parented game window.
	return Engine.is_embedded_in_editor()
static func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		apply(int(config.get_value("display", "resolution", 0)), bool(config.get_value("display", "fullscreen", false)), false)
static func apply(index: int, fullscreen: bool, save: bool = true) -> String:
	index = clampi(index, 0, RESOLUTIONS.size() - 1)
	if save:
		var config := ConfigFile.new()
		config.set_value("display", "resolution", index)
		config.set_value("display", "fullscreen", fullscreen)
		if config.save(PATH) != OK: return "设置保存失败，请检查用户目录是否可写。"
	if embedded_run(): return "设置已保存。编辑器嵌入窗口由编辑器控制大小，点击「独立窗口运行」应用。"
	if DisplayServer.get_name() == "headless": return "设置已保存。"
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null: return "无法取得游戏窗口。"
	var window: Window = tree.root
	# Change the Window node as well as the OS window. In particular, leave
	# maximized/fullscreen mode before sizing, and retain the fixed pixel canvas.
	window.mode = Window.MODE_WINDOWED
	window.size = RESOLUTIONS[index]
	var screen: Rect2i = DisplayServer.screen_get_usable_rect(window.current_screen)
	window.position = screen.position + Vector2i(maxi(0, (screen.size.x - window.size.x) / 2), maxi(0, (screen.size.y - window.size.y) / 2))
	if fullscreen:
		window.mode = Window.MODE_FULLSCREEN
		return "全屏使用桌面分辨率；退出全屏时恢复所选窗口分辨率。"
	return "已应用窗口分辨率 %d × %d。" % [window.size.x, window.size.y]
static func launch_standalone() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var game: Node = tree.get_first_node_in_group("yintian_game") if tree != null else null
	var arguments := PackedStringArray(["--path", ProjectSettings.globalize_path("res://"), "--windowed", "--audio-driver", AudioServer.get_driver_name()])
	if game != null:
		game.persist()
		if game.save_failed: return "进度保存失败，未切换窗口。"
		arguments.append("res://scenes/main.tscn")
	var process_id: int = OS.create_process(OS.get_executable_path(), arguments)
	if process_id <= 0: return "无法打开独立窗口，请在 Godot 中关闭嵌入运行再启动。"
	if tree != null and embedded_run(): tree.call_deferred("quit")
	return "已打开独立游戏窗口，画面设置将在新窗口生效。"
static func panel() -> VBoxContainer:
	var box := VBoxContainer.new()
	var info := Label.new()
	info.text = "最近邻采样与整数像素缩放。\n窗口分辨率改变窗口大小；全屏使用桌面分辨率。"
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color("424c42"))
	box.add_child(info)
	var resolutions := OptionButton.new()
	resolutions.name = "ResolutionChoice"
	for size_value in RESOLUTIONS: resolutions.add_item("%d × %d" % [size_value.x, size_value.y])
	var fullscreen := CheckButton.new()
	fullscreen.name = "FullscreenChoice"
	fullscreen.text = "全屏（取消后使用上方窗口分辨率）"
	var config := ConfigFile.new()
	config.load(PATH)
	resolutions.select(clampi(int(config.get_value("display", "resolution", 0)), 0, 2))
	fullscreen.button_pressed = bool(config.get_value("display", "fullscreen", false))
	box.add_child(resolutions)
	box.add_child(fullscreen)
	var status := Label.new()
	status.name = "DisplayStatus"
	status.custom_minimum_size.x = 390
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 11)
	status.add_theme_color_override("font_color", Color("424c42"))
	status.text = "编辑器嵌入运行：需打开独立窗口才能改变窗口大小。" if embedded_run() else "选择分辨率后点击应用。"
	var apply_button := Button.new()
	apply_button.text = "应用分辨率"
	apply_button.pressed.connect(func():
		status.text = apply(resolutions.selected, fullscreen.button_pressed)
	)
	box.add_child(apply_button)
	if embedded_run():
		var standalone := Button.new()
		standalone.text = "独立窗口运行"
		standalone.pressed.connect(func():
			apply(resolutions.selected, fullscreen.button_pressed)
			status.text = launch_standalone()
		)
		box.add_child(standalone)
	box.add_child(status)
	return box
