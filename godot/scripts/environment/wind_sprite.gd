class_name YinWindSprite
extends Sprite2D
var world: FarmWorld
var phase: float
func _ready() -> void:
	phase = get_parent().position.x * 0.03 + get_parent().position.y * 0.02
	var wind_material := ShaderMaterial.new()
	wind_material.shader = preload("res://shaders/canopy.gdshader")
	wind_material.set_shader_parameter("phase", phase)
	material = world.shared_canopy() if world is YinContinentWorld else wind_material
func _process(delta: float) -> void:
	if not is_instance_valid(world) or world.environment == null: return
	if is_instance_valid(world.player) and get_parent().position.distance_squared_to(world.player.position)>640000:return
	var environment: YinEnvironment = world.environment
	if not world is YinContinentWorld:
		material.set_shader_parameter("clock_time", environment.time)
		material.set_shader_parameter("wind", environment.wind)
		material.set_shader_parameter("wetness", environment.wetness)
	if not is_instance_valid(world.player): return
	var relative: Vector2 = world.player.position - get_parent().position
	var under_canopy: bool = absf(relative.x) < 43 and relative.y < -8 and relative.y > -110
	modulate.a = move_toward(modulate.a, 0.46 if under_canopy else 1.0, delta * 2.5)
