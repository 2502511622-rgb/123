class_name YinInventorySlot
extends Button
signal selected(slot: YinInventorySlot, half: bool)
signal transferred
var model: YinInventoryModel
var index: int
var picture: TextureRect
var name_label: Label
var count_label: Label
const ICON_IDS = ["candle_seeds", "vine_seeds", "gourd_seeds", "rice_seeds", "candle", "vine", "gourd", "rice", "oil", "talisman", "bone", "ash", "wood", "stone", "paper_lamp", "ward_stake", "light_ammo", "rifle_ammo", "scrap"]
func _ready() -> void:
	custom_minimum_size = Vector2(43, 38)
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
	picture = TextureRect.new()
	picture.position = Vector2(4, 3)
	picture.size = Vector2(16, 16)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	name_label = Label.new()
	name_label.position = Vector2(2, 23)
	name_label.size = Vector2(39, 13)
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", Color("3b4f44"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)
	count_label = Label.new()
	count_label.position = Vector2(21, 5)
	count_label.size = Vector2(20, 12)
	count_label.add_theme_font_size_override("font_size", 9)
	count_label.add_theme_color_override("font_color", Color("3b4f44"))
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count_label)
	pressed.connect(func(): selected.emit(self, false))
	render()
func render() -> void:
	var item: Dictionary = model.slots()[index]
	text = ""
	name_label.text = "" if item.id == "" else YinItemCatalog.spec(item.id).display_name
	name_label.add_theme_font_size_override("font_size", 6 if name_label.text.length() > 4 else 8)
	count_label.text = "·" if item.id == "" else str(item.count)
	picture.texture = null
	if item.id != "" and ICON_IDS.has(item.id):
		var atlas := AtlasTexture.new()
		atlas.atlas = preload("res://assets/items.png")
		atlas.region = Rect2(ICON_IDS.find(item.id) * 16, 0, 16, 16)
		picture.texture = atlas
	tooltip_text = "空格" if item.id == "" else YinItemCatalog.spec(item.id).display_name + "\n" + YinItemCatalog.spec(item.id).description + "\n左键交换 / 右键取一半 / 拖拽移动"
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
	return {"candle_seeds": "烛种", "vine_seeds": "钱种", "gourd_seeds": "葫种", "rice_seeds": "稻种", "candle": "烛穗", "vine": "钱藤", "gourd": "葫芦", "rice": "魂稻", "light_ammo": "轻型弹药", "rifle_ammo": "步枪弹药", "scrap": "铳器零件"}.get(id, YinItemCatalog.spec(id).display_name)
