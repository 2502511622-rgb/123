class_name YinHitbox
extends Area2D
var actor: CharacterBody2D
var radius: float = 49
func _ready() -> void:
	collision_layer = 8
	collision_mask = 16
	monitoring = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
func targets(facing: Vector2) -> Array:
	if actor == null: return []
	var shape := CircleShape2D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, actor.global_position)
	query.collision_mask = 16
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var found: Array = []
	for result in actor.get_world_2d().direct_space_state.intersect_shape(query, 32):
		var box: YinHurtbox = result.collider as YinHurtbox
		if box == null or not is_instance_valid(box.actor) or box.actor.is_queued_for_deletion(): continue
		var enemy: YinEnemy = box.actor as YinEnemy
		if enemy == null or enemy.record.dead or actor.global_position.distance_to(enemy.global_position) > radius: continue
		if facing.dot(actor.global_position.direction_to(enemy.global_position)) < -0.1: continue
		var ray := PhysicsRayQueryParameters2D.create(actor.global_position + Vector2(0, -4), enemy.global_position + Vector2(0, -4), 1)
		if not actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		found.append(enemy)
	found.sort_custom(func(a, b): return actor.global_position.distance_squared_to(a.global_position) < actor.global_position.distance_squared_to(b.global_position))
	return found
