extends Control
var state: FarmState
var game: Node2D
var time: float = 0.0
var lighting: ShaderMaterial
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var veil := ColorRect.new()
	veil.size = Vector2(640, 360)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lighting = ShaderMaterial.new()
	lighting.shader = preload("res://shaders/atmosphere.gdshader")
	veil.material = lighting
	add_child(veil)
func _process(delta: float) -> void:
	if state == null or not is_instance_valid(game.world): return
	if game.modal == null: time += delta
	var transform: Transform2D = game.world.get_global_transform_with_canvas()
	var points := PackedVector4Array()
	for node in get_tree().get_nodes_in_group("art_lights"):
		if not node.is_inside_tree() or not game.world.is_ancestor_of(node): continue
		var at: Vector2 = transform * (node.global_position - Vector2(0, 22))
		if at.x < -85 or at.y < -85 or at.x > 725 or at.y > 445: continue
		points.append(Vector4(at.x, at.y, 76, 1.0 + sin(time * 2 + at.x) * 0.05))
		if points.size() >= 24: break
	var count: int = points.size()
	while points.size() < 24: points.append(Vector4.ZERO)
	var environment: YinEnvironment = game.world.environment
	if environment != null:
		lighting.set_shader_parameter("light_field", environment.light_field.viewport.get_texture())
		lighting.set_shader_parameter("rain", environment.rain)
		lighting.set_shader_parameter("wetness", environment.wetness)
	lighting.set_shader_parameter("fog_tint",Color(YinRegionStyle.profile(state.zone).fog))
	lighting.set_shader_parameter("focus_strength",0.25 if state.zone in ["hall","shop"] else 0.52)
	lighting.set_shader_parameter("sunshine", clampf(1.0-absf(state.minutes-840)/480.0, 0, 1) if state.zone not in ["hall", "shop"] else 0.0)
	lighting.set_shader_parameter("warmth", clampf(1.0-absf(state.minutes-1035)/150.0, 0, 1))
	lighting.set_shader_parameter("lights", points)
	lighting.set_shader_parameter("light_count", count)
	lighting.set_shader_parameter("night", night_alpha() / 0.59)
	lighting.set_shader_parameter("mist", 0.0 if environment != null and environment.indoor else 0.12 if state.zone in ["graveyard", "temple", "sunken"] else (0.07 if state.zone in ["forest", "island"] else 0.025))
	lighting.set_shader_parameter("clock_time", time)
	lighting.set_shader_parameter("world_offset", -transform.origin)
	lighting.set_shader_parameter("hero", transform * game.player.position)
	queue_redraw()
func night_alpha() -> float:
	if state == null or state.zone in ["hall", "shop"]: return 0
	var alpha: float = clampf((state.minutes - 1020) / 300, 0, 0.59)
	return maxf(0.17, alpha) if state.zone == "graveyard" else alpha
