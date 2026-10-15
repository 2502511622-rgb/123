class_name YinHeldWeapon
extends Node2D
var actor: FarmPlayer
func _ready() -> void:
	# Equipment is a separate canvas item: avatar palette changes cannot recolor it.
	material=ShaderMaterial.new()
	material.shader=preload("res://shaders/hit_flash.gdshader")
	material.set_shader_parameter("avatar_enabled",false)
func _draw() -> void:
	if is_instance_valid(actor):actor.draw_held_item(self)
