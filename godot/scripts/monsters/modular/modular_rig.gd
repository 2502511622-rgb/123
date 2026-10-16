class_name YinModularRig
extends Node2D
var pack: String
var joints: Dictionary={}
var stumps: Dictionary={}
var hit_frame: int=-1
var animation: AnimationPlayer
var removed: Array=[]
var facing: float=1
func setup(kind: String) -> void:
 pack=YinEnemyPack.pack_for(kind)
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 use_parent_material=true
 for part in ["leg_left","leg_right","arm_left","arm_right","body","head"]:
  var node=Node2D.new();node.name=part;add_child(node);joints[part]=node
  var sprite=Sprite2D.new();sprite.name="Sprite";sprite.texture=YinEnemyPack.texture(pack)
  sprite.region_enabled=true;sprite.region_rect=YinEnemyPack.region(YinEnemyPack.PARTS.find(part));sprite.centered=false
  sprite.offset=-YinEnemyPack.PIVOTS[part];sprite.use_parent_material=true
  node.use_parent_material=true;node.add_child(sprite)
  if part in YinEnemyPack.LIMBS or part=="head":
   var stump=Sprite2D.new();stump.name="Stump_"+part;stump.texture=sprite.texture
   stump.region_enabled=true;stump.region_rect=YinEnemyPack.region(14 if part=="head" else 6+YinEnemyPack.LIMBS.find(part))
   stump.centered=false;stump.offset=Vector2(-32,-61);stump.visible=false;stump.use_parent_material=true
   add_child(stump);stumps[part]=stump
 for part in stumps:move_child(stumps[part],get_child_count()-1)
 animation=AnimationPlayer.new();animation.name="HitAnimation";add_child(animation)
 var library=AnimationLibrary.new();var hurt=Animation.new();hurt.length=0.19
 var track=hurt.add_track(Animation.TYPE_VALUE);hurt.track_set_path(track,NodePath(".:hit_frame"));hurt.value_track_set_update_mode(track,Animation.UPDATE_DISCRETE)
 for i in range(3):hurt.track_insert_key(track,i*0.055,i)
 hurt.track_insert_key(track,0.185,-1);library.add_animation("hit",hurt);animation.add_animation_library("",library)
 animation.animation_finished.connect(func(_clip):hit_frame=-1)
func present(kind: String,missing: Array,clock: float,moving: bool,attack: bool,flip: bool,tint: Color) -> void:
 if joints.is_empty():setup(kind)
 removed=missing.duplicate();facing=-1 if flip else 1;scale.x=facing
 modulate=tint
 var anatomy=YinEnemyPack.anatomical(kind)
 for part in joints:
  var absent=YinEnemyPack.missing(part,missing) or (part not in ["body","head"] and part not in anatomy)
  joints[part].visible=not absent
  if YinEnemyPack.missing(part,missing):
   var sprite=joints[part].get_node_or_null("Sprite")
   if sprite!=null and not sprite.is_queued_for_deletion():sprite.queue_free()
  joints[part].transform=YinEnemyPack.transform_for(part,clock,moving,attack,hit_frame)
  if stumps.has(part):stumps[part].visible=YinEnemyPack.missing(part,missing) and part in anatomy
 align_stumps()
func align_stumps() -> void:
 for part in stumps:
  stumps[part].transform=joints.body.transform*Transform2D(0,-(YinEnemyPack.PIVOTS.body-Vector2(32,61)))
func hit() -> void:
 if animation!=null:animation.stop();animation.play("hit")
func detach(part: String,parent: Node,direction: Vector2) -> YinSeveredLimb:
 if not joints.has(part):return null
 var limb=YinSeveredLimb.new();limb.part=part;limb.joint=part
 limb.source_texture=YinEnemyPack.texture(pack);limb.source_atlas=limb.source_texture
 limb.source_region=YinEnemyPack.region(YinEnemyPack.PARTS.find(part));limb.origin_region=limb.source_region
 limb.draw_size=Vector2.ONE*64;limb.sprite_offset=-YinEnemyPack.PIVOTS[part]
 var drop_height=maxf(8,global_position.y-joints[part].global_position.y)
 limb.position=parent.to_local(joints[part].global_position+Vector2(0,drop_height))
 limb.visual_basis=joints[part].global_transform;limb.visual_basis.origin=Vector2.ZERO
 limb.velocity=direction.rotated(randf_range(-0.5,0.5))*randf_range(75,120)
 limb.height=drop_height;parent.add_child(limb)
 joints[part].visible=false
 var sprite=joints[part].get_node_or_null("Sprite")
 if sprite!=null:sprite.queue_free()
 if stumps.has(part):stumps[part].visible=true
 return limb
func stump_positions() -> Array[Vector2]:
 var result: Array[Vector2]=[]
 for part in stumps:
  if stumps[part].visible:result.append(stumps[part].to_global(YinEnemyPack.PIVOTS[part]-Vector2(32,61)))
 return result
