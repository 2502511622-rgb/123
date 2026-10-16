class_name YinSeveredLimb
extends RigidBody2D
var source_atlas: Texture2D
var origin_region := Rect2()
var joint: String = ""
var source_region := Rect2()
var draw_size := Vector2.ZERO
var flip_h: bool = false
var part: String = "arm"
var velocity := Vector2.ZERO
var sprite_offset := Vector2(INF,INF)
var visual: Sprite2D
var lifetime: float=0 # Same retention policy as the residual torso; zero is permanent.
var bounce_count: int=0
var visual_basis: Transform2D=Transform2D.IDENTITY
var height: float = 12
var lift: float = 95
var age: float = 0
var source_texture: Texture2D = YinActorArt.ROSTER
var modal_velocity := Vector2.ZERO
var modal_spin: float=0
func _ready() -> void:
 add_to_group("severed_limbs")
 lifetime=YinDisplaySettings.corpse_lifetime
 z_as_relative=false;z_index=2
 collision_layer=32;collision_mask=1|8|32
 gravity_scale=0;linear_damp=3.5;angular_damp=4.0;mass=0.3
 continuous_cd=RigidBody2D.CCD_MODE_CAST_SHAPE
 var material_value=PhysicsMaterial.new();material_value.bounce=0.28;material_value.friction=0.9;physics_material_override=material_value
 var shape=CollisionShape2D.new();var capsule=CapsuleShape2D.new();capsule.radius=3;capsule.height=16;shape.shape=capsule
 if is_finite(sprite_offset.x):
  shape.position=visual_basis*Vector2(0,-8 if part=="head" else 9)
  shape.rotation=visual_basis.get_rotation()
 add_child(shape)
 visual=Sprite2D.new();visual.texture=source_texture;visual.region_enabled=true;visual.region_rect=source_region
 visual.centered=false;visual.offset=sprite_offset if is_finite(sprite_offset.x) else -draw_size/2
 visual.scale=draw_size/source_region.size if source_region.has_area() else Vector2.ONE
 visual.flip_h=flip_h;add_child(visual)
 if visual_basis!=Transform2D.IDENTITY:visual.transform=visual_basis
 visual.position=Vector2(0,-height).rotated(-global_rotation)
 linear_velocity=velocity;angular_velocity=randf_range(-8,8)
 # Physics entities stay with the world, never with their source CharacterBody.
 sleeping_state_changed.connect(func():
  if sleeping and height<=0:set_physics_process(false))
 if lifetime>0:
  var tween=create_tween();tween.tween_interval(lifetime);tween.tween_property(self,"modulate:a",0.0,2);tween.tween_callback(queue_free)
func _physics_process(delta: float) -> void:
 var game=get_tree().get_first_node_in_group("yintian_game")
 if game!=null and game.modal!=null:
  if not freeze:
   modal_velocity=linear_velocity;modal_spin=angular_velocity;freeze=true
  return
 if freeze:
  freeze=false;linear_velocity=modal_velocity;angular_velocity=modal_spin
 age+=delta
 if height>0 or lift>0:
  lift-=delta*420;height+=lift*delta
  if height<=0:
   height=0;bounce_count+=1
   z_index=0
   if bounce_count<2:lift=absf(lift)*0.25
   else:lift=0
 visual.position=Vector2(0,-height).rotated(-global_rotation)
 if age>1.5 and height<=0 and linear_velocity.length()<3:
  sleeping=true;set_physics_process(false)
