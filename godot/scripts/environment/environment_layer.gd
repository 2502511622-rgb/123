class_name YinEnvironmentLayer
extends Node2D
var environment: YinEnvironment
var foreground: bool = false
func _draw() -> void:
	if foreground: environment.draw_front(self)
	else: environment.draw_ground(self)
