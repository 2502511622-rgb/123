extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
func frames(count: int = 5) -> void:
	for i in range(count): await process_frame
func click(control: Control) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
func run() -> void:
	ThemeDB.fallback_font = preload("res://assets/mossfield-font.ttf")
	root.theme = YinPixelTheme.install()
	var graphical: bool = DisplayServer.get_name() != "headless"
	for index in range(3):
		YinDisplaySettings.apply(index, false)
		await frames()
		var config := ConfigFile.new()
		check(config.load(YinDisplaySettings.PATH) == OK and config.get_value("display", "resolution") == index, "each resolution persists")
		if graphical and not YinDisplaySettings.embedded_run():
			check(root.size == YinDisplaySettings.RESOLUTIONS[index] and DisplayServer.window_get_size() == root.size, "Window and OS agree on selected resolution")
	YinDisplaySettings.apply(0, false)
	await frames()
	var view := YinDisplaySettings.panel()
	view.position = Vector2(100, 50)
	root.add_child(view)
	await frames()
	var choice: OptionButton = view.get_node("ResolutionChoice")
	await click(choice)
	await frames()
	var popup: PopupMenu = choice.get_popup()
	popup.set_focused_item(1)
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.physical_keycode = KEY_ENTER
		event.pressed = pressed
		event.window_id = popup.get_window_id()
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
	check(choice.selected == 1, "dropdown selection changes requested resolution")
	var apply_button: Button
	for child in view.get_children():
		if child is Button and child.text == "应用分辨率": apply_button = child
	await click(apply_button)
	await frames()
	check("1920" in view.get_node("DisplayStatus").text if graphical and not YinDisplaySettings.embedded_run() else not view.get_node("DisplayStatus").text.is_empty(), "real mouse click applies resolution and shows result")
	if graphical and not YinDisplaySettings.embedded_run():
		check(root.size == Vector2i(1920, 1080), "settings UI changes actual graphics window")
		root.mode = Window.MODE_MAXIMIZED
		await frames()
		YinDisplaySettings.apply(0, false)
		await frames()
		check(root.mode == Window.MODE_WINDOWED and root.size == Vector2i(1280, 720), "maximized window can return to selected size")
		var message: String = YinDisplaySettings.apply(1, true)
		await frames()
		check(root.mode == Window.MODE_FULLSCREEN and "桌面分辨率" in message, "fullscreen clearly reports desktop resolution behavior")
		YinDisplaySettings.apply(1, false)
		await frames()
		check(root.mode == Window.MODE_WINDOWED and root.size == Vector2i(1920, 1080), "leaving fullscreen applies chosen window size")
		root.size = Vector2i(800, 600)
		await frames()
		YinDisplaySettings.load_settings()
		await frames()
		check(root.size == Vector2i(1920, 1080), "reloading preferences reapplies selected size")
	if YinDisplaySettings.embedded_run():
		check("编辑器嵌入" in view.get_node("DisplayStatus").text, "embedded runs explain why editor controls size")
		check(view.get_children().any(func(child): return child is Button and child.text == "独立窗口运行"), "embedded runs offer standalone launch")
	YinDisplaySettings.apply(0, false)
	view.queue_free()
	await frames()
	print("Display settings: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
