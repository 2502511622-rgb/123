extends SceneTree
class Stage extends Node2D:
 var kinds=["完整","断左臂","断右腿","双腿断裂","仅残躯"]
 func _draw():
  draw_rect(Rect2(0,0,1100,480),Color("18212b"))
  var font=preload("res://assets/mossfield-font.ttf")
  draw_string(font,Vector2(22,30),"Q版山魈 · 完整肢体与断面实机对照",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("e0d4b5"))
  for i in range(5):
   draw_line(Vector2(30+i*220,276),Vector2(205+i*220,276),Color("3c484c"),1)
   draw_string(font,Vector2(65+i*220,320),kinds[i],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d8ccb1"))
  draw_string(font,Vector2(22,454),"离体手脚为独立物理实体；躯干不挖空，肩部与腿根显示断面。",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("aaa997"))
var viewport: SubViewport
var stage: Stage
func _initialize():call_deferred("run")
func frames(n=2):
 for i in range(n):await physics_frame
func capture(label: String):
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
 await process_frame;await RenderingServer.frame_post_draw
 viewport.get_texture().get_image().save_png(folder.path_join(label+".png"))
func run():
 viewport=SubViewport.new();viewport.size=Vector2i(1100,480);viewport.world_2d=World2D.new();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 stage=Stage.new();viewport.add_child(stage)
 var rigs=[]
 for i in range(5):
  var wrapper=Node2D.new();wrapper.position=Vector2(112+i*220,270);wrapper.scale=Vector2(3,3);stage.add_child(wrapper)
  var rig=YinModularRig.new();wrapper.add_child(rig);rig.setup("brute");rig.present("brute",[],0,false,false,false,Color.WHITE);rigs.append(rig)
 await frames();await capture("parts-before")
 var missing=[[],["arm_left"],["leg_right"],["leg_left","leg_right"],["arm_left","arm_right","leg_left","leg_right","head"]]
 for i in range(1,5):
  for part in missing[i]:rigs[i].detach(part,stage,Vector2(-.6 if part.ends_with("left") else .6,.2))
  rigs[i].present("brute",missing[i],0,false,false,false,Color.WHITE)
  if i>=3:rigs[i].position.y=20
 await frames(2);await capture("parts-cut")
 for frame in range(48):
  rigs[0].action_progress=fposmod(frame/40.0,1)
  rigs[0].present("brute",[],frame*.025,true,true,false,Color.WHITE)
  await frames(2)
  if frame%2==0:await capture("parts-motion-%03d"%frame)
 await capture("parts-after")
 print("PARTS28 physics fragments=",get_nodes_in_group("severed_limbs").size())
 viewport.queue_free();await frames();quit()
