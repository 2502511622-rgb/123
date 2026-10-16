class_name YinAimResolver
extends RefCounted
static func world_point(world: Node2D,screen_position: Vector2) -> Vector2:
	return world.get_global_transform_with_canvas().affine_inverse()*screen_position
static func direction(world: Node2D,actor: Node2D,screen_position: Vector2) -> Vector2:
	return actor.global_position.direction_to(world_point(world,screen_position))
