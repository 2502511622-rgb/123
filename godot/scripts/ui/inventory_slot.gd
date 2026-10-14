class_name YinInventorySlot
extends Button
signal selected(slot: YinInventorySlot, half: bool)
signal transferred
var model: YinInventoryModel
var index: int
func _ready() -> void:
	custom_minimum_size = Vector2(43, 36)
	focus_mode = Control.FOCUS_NONE
	toggle_mode = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color("bdc4a5")
	style.border_color = Color("748675")
	style.set_border_width_all(1)
	style.content_margin_left = 4
	style.content_margin_right = 4
	add_theme_stylebox_override("normal", style)
	add_theme_color_override("font_color", Color("3b4f44"))
	add_theme_font_size_override("font_size", 9)
	pressed.connect(func(): selected.emit(self, false))
	render()
func render() -> void:
	var item: Dictionary = model.slots()[index]
	text = "·" if item.id == "" else short_name(item.id) + "\n" + str(item.count)
	tooltip_text = "空格" if item.id == "" else YinItemCatalog.spec(item.id).description + "\n左键交换 / 右键取一半 / 拖拽移动"
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		selected.emit(self, true)
		accept_event()
func _get_drag_data(_at: Vector2) -> Variant:
	var cell: Dictionary = model.slots()[index]
	if cell.id == "": return null
	var preview := Label.new()
	preview.text = YinItemCatalog.spec(cell.id).display_name + " × " + str(cell.count)
	set_drag_preview(preview)
	return {"model": model, "index": index, "amount": -1}
func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("model") is YinInventoryModel and data.has("index")
func _drop_data(_at: Vector2, data: Variant) -> void:
	if data.model.move(int(data.index), model, index, int(data.amount)): transferred.emit()

func short_name(id: String) -> String:
	return {"candle_seeds": "烛种", "vine_seeds": "钱种", "gourd_seeds": "葫种", "rice_seeds": "稻种", "candle": "烛穗", "vine": "钱藤", "gourd": "葫芦", "rice": "魂稻"}.get(id, YinItemCatalog.spec(id).display_name)
