class_name YinPixelTheme
extends RefCounted
const TEXT = Color("eee3cb")
const MUTED = Color("aaaab0")
const GOLD = Color("cfad75")
const INK = Color("1b202b")
static func box(bg: String = "1b3330", border: String = "66745c") -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	var palettes: Dictionary={"1b3330":"202430","172e2cf2":"171c27ed","1f3732":"232936","2d493d":"343b49","3d5140":"444b57","223a33":"252c39","102624":"171c27","152c2b":"1b202b"}
	s.bg_color = Color(palettes.get(bg,bg))
	s.border_color = Color(border)
	s.set_border_width_all(1)
	s.set_corner_radius_all(0)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	s.shadow_color = Color("090d16b0")
	s.shadow_size = 3
	s.shadow_offset = Vector2(1, 2)
	return s
static func focus() -> StyleBoxFlat:
	var s := box("00000000", "ceb47c")
	s.draw_center = false
	s.shadow_size = 0
	return s
static func install() -> Theme:
	var t := Theme.new()
	t.default_font = preload("res://assets/mossfield-font.ttf")
	t.default_font_size = 12
	for type_name in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type_name, box())
		t.set_stylebox("hover", type_name, box("2c463b", "c2a96e"))
		t.set_stylebox("pressed", type_name, box("3c5140", "d1b67e"))
		t.set_stylebox("focus", type_name, focus())
		t.set_stylebox("disabled", type_name, box("172e2c", "3d5349"))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: t.set_color(state, type_name, TEXT)
		t.set_color("font_disabled_color", type_name, Color("6c7f70"))
	for type_name in ["Label", "CheckButton", "CheckBox", "PopupMenu", "LineEdit"]: t.set_color("font_color", type_name, TEXT)
	t.set_stylebox("panel", "PopupMenu", box("152c2b", "a28e61"))
	t.set_stylebox("normal", "LineEdit", box("102624", "68775f"))
	t.set_stylebox("focus", "LineEdit", focus())
	t.set_color("caret_color", "LineEdit", GOLD)
	t.set_color("selection_color", "LineEdit", Color("53694c"))
	t.set_stylebox("panel", "TooltipPanel", box("102725f5", "b19c69"))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_stylebox("scroll", "VScrollBar", box("122926", "31473d"))
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]: t.set_stylebox(state, "VScrollBar", box("718066", "a59d72"))
	return t
