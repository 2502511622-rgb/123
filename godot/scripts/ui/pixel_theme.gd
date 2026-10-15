class_name YinPixelTheme
extends RefCounted
static func box(bg: String = "e9e0c9", border: String = "798274") -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(bg)
	s.border_color = Color(border)
	s.set_border_width_all(1)
	s.set_corner_radius_all(0)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	s.shadow_color = Color("1e292bcc")
	s.shadow_size = 0
	s.shadow_offset = Vector2(2, 2)
	return s
static func install() -> Theme:
	var t := Theme.new()
	t.default_font = preload("res://assets/mossfield-font.ttf")
	t.default_font_size = 12
	t.set_stylebox("normal", "Button", box())
	t.set_stylebox("hover", "Button", box("f0ddb0", "aa8351"))
	t.set_stylebox("pressed", "Button", box("9caf9b", "405c53"))
	t.set_stylebox("focus", "Button", box("e1d2ae", "ba8050"))
	t.set_stylebox("disabled", "Button", box("7c8274", "4c574e"))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", Color("33453e"))
	t.set_color("font_color", "Label", Color("e6d8b8"))
	return t
