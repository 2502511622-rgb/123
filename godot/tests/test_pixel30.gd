extends SceneTree
class Probe extends Node2D:
 var pose: Dictionary
 func _draw():YinActorArt.draw_pose(self,pose)
var failures=0
var checks=0
func _initialize():call_deferred("run")
func check(value: bool,label: String):
 checks+=1;print("PIXEL30 ","PASS " if value else "FAIL ",label)
 if not value:failures+=1
func run():
 var image=YinActorArt.PIXEL_WALK.get_image()
 for direction in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
  var poses={};var silhouettes={};var hands={}
  for i in range(8):
   var pose=YinActorArt.hero_motion_pose(direction,(i+.1)/16.0,true,0,0)
   var region=image.get_region(Rect2i(pose.source));poses[hash(region.get_data())]=true
   var alpha=Image.create(96,96,false,Image.FORMAT_R8)
   var at=Vector2i(pose.destination.position)+Vector2i(48,90)
   for y in range(region.get_height()):
    for x in range(region.get_width()):
     if at.y+y>=68:alpha.set_pixel(at.x+x,at.y+y,Color(region.get_pixel(x,y).a,0,0))
   silhouettes[hash(alpha.get_data())]=true;hands[pose.hand]=true
   check(pose.get("authored_frames",false) and pose.get("rigid",false),"walk uses source pixels without leg deformation "+str(direction)+str(i))
  check(poses.size()==8 and silhouettes.size()>=6,"eight source poses and independently changing lower-body silhouette "+str(direction))
  check(hands.size()>=4,"weapon grip follows moving source hand "+str(direction))
  var combat={}
  for i in range(100):
   var pose=YinActorArt.hero_motion_pose(direction,0,false,.22*(1.0-(i+.1)/100),0)
   combat[pose.source]=true
  var idle=YinActorArt.hero_motion_pose(direction,0,false,0,0)
  var hurt=YinActorArt.hero_motion_pose(direction,0,false,0,.3)
  check(combat.size()==6 and not combat.has(idle.source) and not combat.has(hurt.source) and idle.source!=hurt.source,"six strike phases, separate idle and hurt "+str(direction))
 for id in range(1,7):
  var frames={}
  for state in [[0,false,false],[.16,true,false],[.46,true,false],[0,false,true]]:
   var pose=YinActorArt.npc_pose(id,state[0],state[1],state[2])
   frames[pose.source]=true
   check(pose.texture==YinActorArt.NPC and pose.get("authored_frames",false),"resident uses new authored sheet "+str(id))
  check(frames.size()==4,"resident has independent idle, two steps and conversation "+str(id))
 if DisplayServer.get_name()!="headless":
  var viewport=SubViewport.new();viewport.size=Vector2i(192,192);viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
  var probe=Probe.new();probe.position=Vector2(96,180);probe.scale=Vector2(3,3);viewport.add_child(probe)
  var seen={};var folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
  if folder!="":DirAccess.make_dir_recursive_absolute(folder)
  for i in range(8):
   probe.pose=YinActorArt.hero_motion_pose(Vector2.RIGHT,(i+.1)/16.0,true,0,0);probe.queue_redraw()
   await process_frame;await RenderingServer.frame_post_draw
   var rendered=viewport.get_texture().get_image();seen[hash(rendered.get_data())]=true
   if folder!="":rendered.save_png(folder.path_join("walk-%02d.png"%i))
  check(seen.size()==8,"GPU renders eight genuinely different authored poses")
  viewport.queue_free();await process_frame
 print("PIXEL30 RESULT ",checks," checks ",failures," failures");quit(1 if failures else 0)
