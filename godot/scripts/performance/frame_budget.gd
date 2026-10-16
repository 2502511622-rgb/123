class_name YinFrameBudget
extends Node
const TARGET_FPS=60
var game: Node2D
var tier: int=0
var average_ms: float=16.0
var slow: float=0
var fast: float=0
var settle: float=1.0
var world_id: int=0
var debug_visible: bool=false
var debug_label: Label
func _ready() -> void:
 Engine.max_fps=TARGET_FPS
 Engine.physics_ticks_per_second=60
 debug_label=Label.new();debug_label.position=Vector2(210,6);debug_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 debug_label.add_theme_font_size_override("font_size",10);debug_label.visible=false;game.hud.add_child(debug_label)
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F3:
  debug_visible=not debug_visible;debug_label.visible=debug_visible
func _process(delta: float) -> void:
 if is_instance_valid(game.world) and game.world.grass.baked and game.world.get_instance_id()!=world_id:
  world_id=game.world.get_instance_id();apply_tier(tier)
 if game.modal!=null:return
 settle=maxf(0,settle-delta)
 var frame_ms=delta*1000
 average_ms=lerpf(average_ms,frame_ms,1-exp(-delta*2))
 # A 60 Hz cap yields ~16.67 ms even on fast hardware; use measured CPU cost
 # for recovery and sustained over-budget frame time for quality reduction.
 var cpu_ms=Performance.get_monitor(Performance.TIME_PROCESS)*1000
 if settle<=0:
  slow=slow+delta if average_ms>17.0 else 0
  fast=fast+delta if average_ms<16.9 and cpu_ms<10 else 0
  if slow>=1.5 and tier<2:apply_tier(tier+1);slow=0;fast=0;settle=2
  elif fast>=12 and tier>0:apply_tier(tier-1);fast=0;slow=0;settle=3
 if debug_visible:debug_label.text="%d FPS · %.1f ms · %s"%[roundi(1000/maxf(1,average_ms)),average_ms,["完整光影","流畅光影","轻量光影"][tier]]
func apply_tier(value: int) -> void:
 tier=clampi(value,0,2)
 YinActorArt.animation_bands=[8,4,1][tier]
 if not is_instance_valid(game.world):return
 var env: YinEnvironment=game.world.environment
 env.terrain_material.set_shader_parameter("quality",2-tier)
 game.atmosphere.lighting.set_shader_parameter("quality",2-tier)
 # Geometry density changes; walking interaction and real combat stay at 60 Hz.
 for chunk in game.world.grass.chunks:
  var multi: MultiMesh=chunk.back.multimesh
  multi.visible_instance_count=-1 if tier==0 else maxi(1,int(multi.instance_count*(0.65 if tier==1 else 0.35)))
