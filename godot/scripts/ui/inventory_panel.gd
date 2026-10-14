class_name YinInventoryPanel
extends VBoxContainer
signal mutated
signal use_item(id: String)
signal drop_item(id: String)
var bag: YinInventoryModel
var chest: YinInventoryModel
var show_chest: bool = false
var selected_slot: YinInventorySlot
var selected_amount: int = -1
var hint: Label
var controls: Array[YinInventorySlot] = []
func _ready() -> void:
	add_to_group("inventory_panels")
	add_theme_constant_override("separation", 6)
	hint = Label.new()
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color("48584a"))
	hint.text = "左键选中并交换；右键取一半；支持拖拽。"
	add_child(hint)
	if show_chest:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		add_child(row)
		create_grid(bag, "行囊 · 24 格", row)
		create_grid(chest, "义庄仓箱 · 24 格", row)
	else: create_grid(bag, "行囊 · 24 格", self)
	var organize := Button.new()
	organize.text = "整理并合并堆叠"
	organize.pressed.connect(func():
		bag.compact()
		if show_chest: chest.compact()
		selected_slot = null
		refresh()
		mutated.emit()
	)
	add_child(organize)
	var build := Button.new()
	build.text = "放置选中的纸灯 / 阵桩"
	build.pressed.connect(func():
		if selected_slot != null and selected_slot.model.container == "bag":
			var id: String = selected_slot.model.slots()[selected_slot.index].id
			if id in ["paper_lamp", "ward_stake"]: use_item.emit(id)
			else: hint.text = "请选择行囊里的纸灯或阵桩。"
	)
	add_child(build)
	var drop := Button.new()
	drop.text = "丢下选中的一份物品（保留在地图中）"
	drop.pressed.connect(func():
		if selected_slot != null and selected_slot.model.container == "bag":
			var id: String = selected_slot.model.slots()[selected_slot.index].id
			if id != "": drop_item.emit(id)
	)
	add_child(drop)
func create_grid(model: YinInventoryModel, name_text: String, parent: Node) -> void:
	model.sync()
	var column := VBoxContainer.new()
	parent.add_child(column)
	var title := Label.new()
	title.text = name_text
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("48584a"))
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 4)
	column.add_child(grid)
	for i in range(YinInventoryModel.CAPACITY):
		var slot := YinInventorySlot.new()
		slot.model = model
		slot.index = i
		slot.selected.connect(select)
		slot.transferred.connect(func():
			refresh()
			mutated.emit()
		)
		controls.append(slot)
		grid.add_child(slot)
func select(slot: YinInventorySlot, half: bool) -> void:
	var cell: Dictionary = slot.model.slots()[slot.index]
	if selected_slot == null or selected_slot == slot:
		selected_slot = slot if cell.id != "" else null
		selected_amount = maxi(1, int(cell.count / 2)) if half else -1
		hint.text = "选中 %s，点击目标格。Esc 关闭不会丢失物品。" % YinItemCatalog.spec(cell.id).display_name if cell.id != "" else "这是空格。"
		refresh()
	else:
		var ok: bool = selected_slot.model.move(selected_slot.index, slot.model, slot.index, selected_amount)
		selected_slot = null
		hint.text = "物品已移动。" if ok else "不能这样移动，物品保持原状。"
		refresh()
		if ok: mutated.emit()
func refresh() -> void:
	for slot in controls:
		slot.render()
		slot.set_pressed_no_signal(slot == selected_slot)
