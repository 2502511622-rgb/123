# Manual, uncapped rendering benchmark. Do not use --fixed-fps. Uses an isolated save profile.
extends SceneTree
var game
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","")
 if DisplayServer.get_name()=="headless" or "--fixed-fps" in OS.get_cmdline_args():
  print("Benchmark requires a graphical renderer and real elapsed time; omit --headless and --fixed-fps.");quit(1);return
 call_deferred("run")
func frames(n):
 for i in range(n):await process_frame
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(5);game.close_modal()
 Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 for scenario in ["home","combat","forest","coast"]:
  game.state.weather="rain" if scenario=="combat" else "sun"
  game.player.position={"home":YinContinent.HOME+Vector2(0,96),"combat":Vector2(4200,3050),"forest":Vector2(5100,4216),"coast":Vector2(5552,2160)}[scenario]
  game.player.invincible=1000
  var warm=Time.get_ticks_msec()
  while Time.get_ticks_msec()-warm<8000:await process_frame
  var samples:Array=[];var cpu:Array=[];var physics:Array=[];var draws:Array=[]
  var previous=Time.get_ticks_usec()
  for i in range(180):
   await process_frame
   var now=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now
   cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000);physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000);draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
  samples.sort();cpu.sort();physics.sort();draws.sort()
  print("BENCH ",scenario," frame median_ms=",samples[90]," p95_ms=",samples[171]," cpu_ms=",cpu[90]," physics_ms=",physics[90]," draws=",draws[90]," tier=",game.frame_budget.tier)
 root.remove_child(game);game.queue_free();await frames(3);quit()
