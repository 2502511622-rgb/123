class_name YinModularRig
extends Node2D
var pack: String
var frame_index: int=0
var frozen_frame: int=-1
var joints: Dictionary={}
var stumps: Dictionary={}
var hit_frame: int=-1
var animation: AnimationPlayer
var removed: Array=[]
var facing: float=1
var turn_blend: float=1
var action_progress: float=1
var aim_angle: float=0
func setup(kind: String) -> void:
 pack=kind
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 use_parent_material=true
 for part in ["leg_left","leg_right","arm_left","arm_right","body","head"]:
  var node=Node2D.new();node.name=part;add_child(node);joints[part]=node
  var sprite=Sprite2D.new();sprite.name="Sprite";sprite.texture=YinMonsterArt.texture(pack)
  sprite.region_enabled=true;sprite.region_rect=YinMonsterArt.region(frame_index*6+YinMonsterArt.PARTS.find(part));sprite.centered=false
  sprite.offset=-YinMonsterArt.pivot(pack,frame_index,part);sprite.use_parent_material=true
  node.use_parent_material=true;node.add_child(sprite)
  if part in YinEnemyPack.LIMBS or part=="head":
   var stump=Sprite2D.new();stump.name="Stump_"+part;stump.texture=sprite.texture
   stump.region_enabled=true;stump.region_rect=YinMonsterArt.region(24+frame_index*5+YinMonsterArt.PARTS.find(part)-1)
   stump.centered=false;stump.offset=Vector2(-48,-90);stump.visible=false;stump.use_parent_material=true
   add_child(stump);stumps[part]=stump
 if kind in ["bone","archer","gunner","daitengu","rakshasa","yaksha","boss"]:
  var weapon=YinMonsterWeapon28.new();weapon.name="HeldWeapon"
  weapon.weapon="pistol" if kind=="gunner" else "silver_sword" if kind in ["bone","daitengu","yaksha"] else "whip" if kind=="archer" else "sword"
  weapon.position=Vector2(0,17);weapon.rotation=-1.0;weapon.size_value=25 if kind!="boss" else 32
  joints.arm_right.add_child(weapon)
 for part in stumps:move_child(stumps[part],get_child_count()-1)
 animation=AnimationPlayer.new();animation.name="HitAnimation";add_child(animation)
 var library=AnimationLibrary.new();var hurt=Animation.new();hurt.length=0.19
 var track=hurt.add_track(Animation.TYPE_VALUE);hurt.track_set_path(track,NodePath(".:hit_frame"));hurt.value_track_set_update_mode(track,Animation.UPDATE_DISCRETE)
 for i in range(3):hurt.track_insert_key(track,i*0.055,i)
 hurt.track_insert_key(track,0.185,-1);library.add_animation("hit",hurt);animation.add_animation_library("",library)
 animation.animation_finished.connect(func(_clip):hit_frame=-1)
func present(kind: String,missing: Array,clock: float,moving: bool,attack: bool,flip: bool,tint: Color) -> void:
 if joints.is_empty():setup(kind)
 frame_index=frozen_frame if frozen_frame>=0 else YinMonsterArt.frame_at(clock,moving,attack)
 removed=missing.duplicate();facing=-1 if flip else 1
 modulate=tint
 var anatomy=YinEnemyPack.anatomical(kind)
 var action=YinMonsterArt.attack_key(action_progress if attack or action_progress<.999 else 1)
 for part in joints:
  var absent=YinEnemyPack.missing(part,missing) or (part not in ["body","head"] and part not in anatomy)
  joints[part].visible=not absent
  if YinEnemyPack.missing(part,missing):
   var sprite=joints[part].get_node_or_null("Sprite")
   if sprite!=null and not sprite.is_queued_for_deletion():sprite.queue_free()
  var pivot=YinMonsterArt.pivot(pack,frame_index,part)
  joints[part].transform=YinMonsterArt.joint_pose(pack,part,clock*10,moving,action,hit_frame,aim_angle)
  var sprite=joints[part].get_node_or_null("Sprite")
  if sprite!=null:
   sprite.region_rect=YinMonsterArt.region(frame_index*6+YinMonsterArt.PARTS.find(part));sprite.offset=-pivot
  if stumps.has(part):stumps[part].region_rect=YinMonsterArt.region(24+frame_index*5+YinMonsterArt.PARTS.find(part)-1)
  if stumps.has(part):stumps[part].visible=YinEnemyPack.missing(part,missing) and part in anatomy
 align_stumps()
func align_stumps() -> void:
 for part in stumps:
  stumps[part].transform=joints.body.transform*Transform2D(0,-(YinMonsterArt.pivot(pack,0,"body")-Vector2(48,90)))
func hit() -> void:
 if animation!=null:animation.stop();animation.play("hit")
func detach(part: String,parent: Node,direction: Vector2) -> YinSeveredLimb:
 if not joints.has(part):return null
 var limb=YinSeveredLimb.new();limb.part=part;limb.joint=part
 limb.source_texture=YinMonsterArt.texture(pack);limb.source_atlas=limb.source_texture
 limb.source_region=YinMonsterArt.region(frame_index*6+YinMonsterArt.PARTS.find(part));limb.origin_region=limb.source_region
 limb.draw_size=Vector2.ONE*96;limb.sprite_offset=-YinMonsterArt.pivot(pack,frame_index,part)
 var drop_height=maxf(8,global_position.y-joints[part].global_position.y)
 limb.position=parent.to_local(joints[part].global_position+Vector2(0,drop_height))
 limb.visual_basis=joints[part].global_transform;limb.visual_basis.origin=Vector2.ZERO
 limb.velocity=direction.rotated(randf_range(-0.5,0.5))*randf_range(75,120)
 limb.height=drop_height;parent.add_child(limb)
 joints[part].visible=false
 var held=joints[part].get_node_or_null("HeldWeapon")
 if held!=null:
  joints[part].remove_child(held);limb.visual.add_child(held)
  held.position=Vector2(0,17)
 var sprite=joints[part].get_node_or_null("Sprite")
 if sprite!=null:sprite.queue_free()
 if stumps.has(part):stumps[part].visible=true
 return limb
func stump_positions() -> Array[Vector2]:
 var result: Array[Vector2]=[]
 for part in stumps:
  if stumps[part].visible:result.append(stumps[part].to_global(YinMonsterArt.pivot(pack,frame_index,part)-Vector2(48,90)))
 return result

func _process(delta: float) -> void:
 if frozen_frame>=0 or not is_visible_in_tree():return
 var game=get_tree().get_first_node_in_group("yintian_game")
 if game!=null and game.modal!=null:return
 var actor=get_parent().get("actor")
 if actor!=null:
  for key in ["hit_stop","freeze_lock"]:
   var remaining=actor.get(key)
   if remaining!=null and remaining>0:return
 turn_blend=move_toward(turn_blend,facing,delta*12)
 scale.x=(1 if turn_blend>=0 else -1)*maxf(.65,absf(turn_blend))
