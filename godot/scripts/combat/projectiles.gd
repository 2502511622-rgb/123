class_name YinProjectiles
extends Node2D
signal projectile_spawned(friendly: bool)
const LIMIT = 256
var game: Node2D
var world: Node2D
var bullets: Array = []
func spawn(at: Vector2, direction: Vector2, friendly: bool, damage: int, speed: float, distance: float, tint: Color) -> bool:
 if bullets.size() >= LIMIT or direction == Vector2.ZERO: return false
 bullets.append({"at": at, "previous": at, "direction": direction.normalized(), "friendly": friendly, "damage": damage, "speed": speed, "remaining": distance, "color": tint})
 projectile_spawned.emit(friendly)
 return true
func _physics_process(delta: float) -> void:
 if game.modal != null or delta <= 0: return
 if game.world != world: return
 for index in range(bullets.size() - 1, -1, -1):
  var bullet: Dictionary = bullets[index]
  var distance: float = minf(bullet.speed * delta, bullet.remaining)
  var end: Vector2 = bullet.at + bullet.direction * distance
  var ray := PhysicsRayQueryParameters2D.create(bullet.at, end, 17 if bullet.friendly else 3)
  ray.collide_with_areas = bool(bullet.friendly)
  var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(ray)
  if not hit.is_empty():
   if bullet.friendly and hit.collider is YinHurtbox:
    var enemy: YinEnemy = hit.collider.actor as YinEnemy
    if is_instance_valid(enemy) and not enemy.record.dead: enemy.receive_hit(bullet.damage, "bullet")
   elif not bullet.friendly and hit.collider == game.player:
    game.take_damage(bullet.damage)
   if game.world != world: return
   world.effect(hit.position - Vector2(0, 14), bullet.color)
   bullets.remove_at(index)
  else:
   bullet.previous = bullet.at
   bullet.at = end
   bullet.remaining -= distance
   if bullet.remaining <= 0: bullets.remove_at(index)
 queue_redraw()
func _draw() -> void:
 for bullet in bullets:
  var at: Vector2 = (bullet.at - Vector2(0, 14)).round()
  var tail: Vector2 = (at - bullet.direction * minf(18, bullet.at.distance_to(bullet.previous) + 4)).round()
  draw_line(tail, at, bullet.color, 2 if bullet.friendly else 3)
  draw_rect(Rect2(at - Vector2(1, 1), Vector2(3, 3)), Color("fff0ca") if bullet.friendly else Color("e99b85"))
