class_name YinAppearancePanel
extends HBoxContainer
signal applied
var game: Node2D
var draft: Dictionary
var preview: Preview
var controls: Dictionary = {}
class Preview extends Control:
	var panel: YinAppearancePanel
	var clock: float = 0
	var direction := Vector2.DOWN
	func _ready() -> void:
		custom_minimum_size=Vector2(144,154)
		material=ShaderMaterial.new()
		material.shader=preload("res://shaders/hit_flash.gdshader")
	func _process(delta: float) -> void:
		clock+=delta
		queue_redraw()
	func _draw() -> void:
		if panel==null: return
		draw_style_box(YinPixelTheme.box(),Rect2(0,0,144,154))
		var pose: Dictionary=YinActorArt.hero_motion_pose(direction,clock,true,0,0,0.22,int(panel.draft.body))
		YinAppearance.configure(material,panel.draft)
		YinAppearance.pose_uniforms(material,pose)
		material.set_shader_parameter("motion_clock",clock)
		material.set_shader_parameter("motion_amount",0.7)
		draw_set_transform(Vector2(72,125),0,Vector2(1.8,0.5))
		draw_circle(Vector2.ZERO,10,Color("14231f66"))
		draw_set_transform(Vector2(72,125),0,Vector2(1.8,1.8))
		YinActorArt.draw_pose(self,pose)
		draw_set_transform(Vector2.ZERO)
func _ready() -> void:
	draft=game.state.appearance.duplicate(true)
	add_theme_constant_override("separation",12)
	preview=Preview.new()
	preview.name="Preview"
	preview.panel=self
	var left:=VBoxContainer.new()
	add_child(left)
	left.add_child(preview)
	var facing:=HBoxContainer.new()
	left.add_child(facing)
	for entry in [["←",Vector2.LEFT],["↑",Vector2.UP],["↓",Vector2.DOWN],["→",Vector2.RIGHT]]:
		var button:=Button.new()
		button.text=entry[0]
		button.custom_minimum_size=Vector2(32,22)
		button.pressed.connect(func(): preview.direction=entry[1])
		facing.add_child(button)
	var right:=VBoxContainer.new()
	right.custom_minimum_size.x=336
	add_child(right)
	var name_row:=HBoxContainer.new()
	right.add_child(name_row)
	var label:=Label.new()
	label.text="姓名"
	label.custom_minimum_size.x=42
	name_row.add_child(label)
	var input:=LineEdit.new()
	input.name="Name"
	input.add_theme_font_override("font",YinAppearance.name_font())
	input.text=draft.name
	input.max_length=12
	input.placeholder_text="1–12 字"
	input.custom_minimum_size=Vector2(278,24)
	input.text_changed.connect(func(value):
		draft.name=value.strip_edges()
		var save_button: Button=find_child("Apply",true,false)
		if save_button!=null:save_button.text="保存外观"
	)
	name_row.add_child(input)
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",5)
	right.add_child(grid)
	for key in YinAppearance.LABELS:
		var row:=HBoxContainer.new()
		var title:=Label.new()
		title.text=YinAppearance.NAMES[key]
		title.custom_minimum_size.x=34
		title.add_theme_font_size_override("font_size",11)
		row.add_child(title)
		var pick:=OptionButton.new()
		pick.name=key
		pick.custom_minimum_size=Vector2(122,24)
		pick.add_theme_font_size_override("font_size",11)
		for text_value in YinAppearance.LABELS[key]: pick.add_item(text_value)
		pick.select(int(draft[key]))
		pick.item_selected.connect(func(index): draft[key]=index)
		row.add_child(pick)
		grid.add_child(row)
		controls[key]=pick
	var actions:=HBoxContainer.new()
	right.add_child(actions)
	var randomize_button:=Button.new()
	randomize_button.text="随机搭配"
	randomize_button.custom_minimum_size=Vector2(106,26)
	randomize_button.pressed.connect(func():
		for key in YinAppearance.LABELS:
			draft[key]=randi_range(0,YinAppearance.LABELS[key].size()-1)
			controls[key].select(draft[key])
	)
	actions.add_child(randomize_button)
	var apply_button:=Button.new()
	apply_button.name="Apply"
	apply_button.text="保存外观"
	apply_button.custom_minimum_size=Vector2(106,26)
	apply_button.pressed.connect(commit)
	actions.add_child(apply_button)
	var reset_button:=Button.new()
	reset_button.text="默认外观"
	reset_button.custom_minimum_size=Vector2(106,26)
	reset_button.pressed.connect(func():
		for key in YinAppearance.LABELS:
			draft[key]=0
			controls[key].select(0)
	)
	actions.add_child(reset_button)
func commit() -> void:
	if not YinAppearance.validate(draft):
		find_child("Apply",true,false).text="请填写姓名"
		return
	var previous: Dictionary=game.state.appearance
	game.state.appearance=draft.duplicate(true)
	game.player.appearance=game.state.appearance
	YinAppearance.configure(game.player.material,game.state.appearance)
	game.player.queue_redraw()
	game.persist()
	if game.save_failed:
		game.state.appearance=previous
		game.player.appearance=previous
		YinAppearance.configure(game.player.material,previous)
		game.player.queue_redraw()
		find_child("Apply",true,false).text="保存失败"
		return
	applied.emit()
