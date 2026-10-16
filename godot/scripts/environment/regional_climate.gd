class_name YinRegionalClimate
extends RefCounted
## Local events are derived from world coordinates, day and a three-hour weather front.
## They never change the saved sun/rain enum or simulation tick rate.
var environment: YinEnvironment
var forced_event: String=""
var event: String="clear"
var snow: float=0
var dust: float=0
var blood: float=0
var footprints: Array=[]
var breaths: Array=[]
var tracked: Dictionary={}
var interaction_clock: float=0
var rain_target: float=0
var zone: String="village"
const LABELS={"clear":"晴","rain":"雨","snow":"大雪","sandstorm":"沙尘暴","bloodmoon":"血月"}
static func forecast(at: Vector2,day: int,minutes: float,weather: String,override_event: String="") -> String:
 var side=YinContinent.faction(at)
 var roll=posmod(hash("%s:%d:%d"%[side,day,int(minutes/180)]),100)
 var result="rain" if weather=="rain" else "clear"
 if side=="temple":result="sandstorm" if roll<35 else "clear"
 elif side=="island" and (weather=="rain" or roll<45):result="snow"
 elif side=="graveyard" and minutes>=1080 and roll<45:result="bloodmoon"
 if override_event!="":result=override_event
 return result
func update(delta: float) -> void:
 var world=environment.world
 zone=YinContinent.faction(world.player.position)
 event=forecast(world.player.position,world.state.day,world.state.minutes,world.state.weather,forced_event)
 rain_target=1.0 if event=="rain" else 0.0
 snow=move_toward(snow,1.0 if event=="snow" else 0.0,delta*0.7)
 dust=move_toward(dust,1.0 if event=="sandstorm" else 0.0,delta*0.6)
 blood=move_toward(blood,1.0 if event=="bloodmoon" else 0.0,delta*0.6)
 for step in footprints:step.age+=delta
 footprints=footprints.filter(func(s):return s.age<s.life)
 for puff in breaths:puff.age+=delta
 breaths=breaths.filter(func(s):return s.age<1.1)
 interaction_clock+=delta
 if interaction_clock<0.1:return
 interaction_clock=0
 interact()
func interact() -> void:
 var world=environment.world
 var actors=world.combat_index().nearby(world.player.position,500)+world.get_tree().get_nodes_in_group("villagers")+world.get_tree().get_nodes_in_group("companions")+[world.player]
 var view=world.screen_bounds().grow(80)
 var alive: Dictionary={}
 for actor in actors:
  if not is_instance_valid(actor) or actor.is_queued_for_deletion() or not view.has_point(actor.position):continue
  var id=actor.get_instance_id()
  if alive.has(id):continue
  alive[id]=true
  if snow>0.3 and breaths.size()<24 and posmod(int(environment.time*10)+id,28)==0:
   breaths.append({"at":actor.position+Vector2(4,-40),"age":0.0})
  if actor.material is ShaderMaterial:
   var region=YinContinent.faction(actor.position)
   actor.material.set_shader_parameter("environment_tint",Color({"temple":"e2c698","island":"b0c0cb","graveyard":"a2aaa8","village":"b5c2a8"}[region]))
   actor.material.set_shader_parameter("environment_blend",0.28)
   actor.material.set_shader_parameter("snow_cover",snow)
   actor.material.set_shader_parameter("dust_cover",dust if region=="temple" else 0.0)
   actor.material.set_shader_parameter("wind_force",environment.wind)
   actor.material.set_shader_parameter("actor_ground_y",actor.global_position.y)
  var previous: Vector2=tracked.get(id,actor.position)
  var distance=actor.position.distance_to(previous)
  if distance>100:tracked[id]=actor.position;continue
  if distance<12:
   if not tracked.has(id):tracked[id]=actor.position
   continue
  tracked[id]=actor.position
  var type="sand" if YinContinent.faction(actor.position)=="temple" else ("snow" if snow>0.15 else ("wet" if environment.wetness>0.2 else "soil"))
  # Wraiths and fire spirits leave a faint disturbance, not solid human footprints.
  if actor.get("record")!=null and actor.record.get("kind","") in YinBodyProfile.FLOATING:continue
  footprints.append({"at":actor.position,"age":0.0,"life":7.0 if type in ["sand","snow"] else 1.0,"type":type,"direction":previous.direction_to(actor.position),"side":footprints.size()%2})
  if type=="wet" and environment.splashes.size()<90:environment.splashes.append({"at":actor.position,"age":0.0,"water":environment.is_water(actor.position)})
 while footprints.size()>120:footprints.pop_front()
 for id in tracked.keys():
  if not alive.has(id):tracked.erase(id)
func draw_ground(canvas: Node2D) -> void:
 for step in footprints:
  var fade=1.0-step.age/step.life
  var color=Color("67543d") if step.type=="sand" else (Color("64747c") if step.type=="snow" else Color("283b3540"))
  color.a=fade*(0.5 if step.type in ["sand","snow"] else 0.3)
  var side=-2 if step.side==0 else 2
  canvas.draw_set_transform(step.at+step.direction.orthogonal()*side,step.direction.angle()+PI/2)
  canvas.draw_rect(Rect2(-1,-2,2,4),color)
  canvas.draw_set_transform(Vector2.ZERO)
func draw_front(canvas: Node2D) -> void:
 var rect=environment.visible_rect();var time=environment.time
 for puff in breaths:
  var at: Vector2=puff.at+Vector2(puff.age*7,-puff.age*6)
  canvas.draw_circle(at,1+puff.age*2,Color(0.70,0.77,0.8,(1.1-puff.age)*0.15))
 for step in footprints:
  if step.type=="sand" and step.age<0.6:
   canvas.draw_circle(step.at+Vector2(step.age*10,-step.age*4),1+step.age*3,Color(0.60,0.47,0.31,(0.6-step.age)*0.22))
 if snow>0.01:
  for i in range(160):
   var at=rect.position+Vector2(fposmod(i*83+time*(12+i%4*8)+sin(time+i)*5,680)-20,fposmod(i*47+time*(18+i%5*10),400)-20)
   canvas.draw_rect(Rect2(at,Vector2(1 if i%3 else 2,1)),Color(0.78,0.83,0.85,snow*(0.28+i%3*0.16)))
 if dust>0.01:
  canvas.draw_rect(rect,Color(0.66,0.46,0.24,dust*0.13))
  for i in range(65):
   var at=rect.position+Vector2(fposmod(i*83+time*(95+i%4*18),720)-40,fposmod(i*41+sin(time*.9+i)*14,400)-20)
   canvas.draw_line(at,at+Vector2(7+i%8,1),Color(0.72,0.56,0.35,dust*0.18),1)
 if blood>0.01:
  for i in range(14):
   var at=rect.position+Vector2(fposmod(i*73+sin(time*.2+i)*14,640),fposmod(i*53-time*4,360))
   canvas.draw_rect(Rect2(at,Vector2.ONE),Color(0.62,0.20,0.18,blood*0.18))
