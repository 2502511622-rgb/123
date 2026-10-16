class_name YinBloodFX
extends Node2D
## Bounded, independently owned effects: never children of the dying enemy.
var emitter: YinModularRig
var duration: float=-1
var elapsed: float=0
var timer: float=0
static func cell(pack: String,index: int) -> AtlasTexture:
 var result=AtlasTexture.new();result.atlas=YinEnemyPack.texture(pack);result.region=YinEnemyPack.region(index);return result
static func burst(parent: Node,at: Vector2,direction: Vector2,pack: String) -> CPUParticles2D:
 if parent.get_tree().get_nodes_in_group("blood_bursts").size()>=16:return null
 var particles=CPUParticles2D.new();particles.name="ImpactBlood";particles.position=parent.to_local(at)
 particles.add_to_group("blood_bursts");particles.texture=cell(pack,12)
 particles.amount=10;particles.lifetime=0.32;particles.one_shot=true;particles.explosiveness=1.0
 particles.direction=direction;particles.spread=100;particles.initial_velocity_min=35;particles.initial_velocity_max=95
 particles.gravity=Vector2(0,150);particles.scale_amount_min=0.7;particles.scale_amount_max=1.2
 particles.color=Color.WHITE;particles.z_index=3
 parent.add_child(particles);particles.finished.connect(particles.queue_free);particles.emitting=true;return particles
static func stain(parent: Node,at: Vector2,pack: String) -> Sprite2D:
 var old=parent.get_tree().get_nodes_in_group("blood_stains")
 if old.size()>=96:old[0].queue_free()
 var sprite=Sprite2D.new();sprite.name="Bloodstain";sprite.add_to_group("blood_stains")
 sprite.texture=cell(pack,11);sprite.position=parent.to_local(at)
 sprite.z_as_relative=false;sprite.z_index=0 # Ground decal, below actors even in the FX container.
 sprite.rotation=randf_range(-PI,PI);sprite.scale=Vector2.ONE*randf_range(0.5,1.0)
 parent.add_child(sprite)
 var tween=sprite.create_tween();tween.tween_interval(18);tween.tween_property(sprite,"modulate:a",0.0,3);tween.tween_callback(sprite.queue_free)
 return sprite
static func drop(parent: Node,at: Vector2,pack: String,ground: Vector2=Vector2(INF,INF)) -> void:
 if parent.get_tree().get_nodes_in_group("blood_drops").size()>=48:return
 var sprite=Sprite2D.new();sprite.name="BloodDrop";sprite.add_to_group("blood_drops")
 sprite.texture=cell(pack,10);sprite.position=parent.to_local(at);sprite.z_index=2
 parent.add_child(sprite)
 if not is_finite(ground.x):ground=at+Vector2(randf_range(-3,3),randf_range(8,19))
 var tween=sprite.create_tween();tween.tween_property(sprite,"position",parent.to_local(ground),0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
 tween.tween_callback(func():
  if is_instance_valid(parent):stain(parent,ground,pack)
  sprite.queue_free())
func _process(delta: float) -> void:
 var game=get_tree().get_first_node_in_group("yintian_game")
 if game!=null and game.modal!=null:return
 if not is_instance_valid(emitter):queue_free();return
 elapsed+=delta
 if duration>=0 and elapsed>=duration:queue_free();return
 timer-=delta
 if timer>0:return
 timer=0.55
 if game==null or not game.world.screen_bounds().grow(64).has_point(emitter.global_position):return
 for at in emitter.stump_positions():
  var floor_point=Vector2(at.x+randf_range(-3,3),emitter.global_position.y+randf_range(1,5))
  drop(game.world.feedback,at,emitter.pack,floor_point)
