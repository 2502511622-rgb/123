extends SceneTree
var game
var checks=0
var failures=0
func _initialize():
 OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=3):
 for i in range(n):await physics_frame
func check(ok: bool,label: String):
 checks+=1;print("POLISH30 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func texts(node: Node) -> String:
 var result=node.text if node is Label or node is Button else ""
 for child in node.get_children():result+="\n"+texts(child)
 return result
func button(node: Node,label: String) -> Button:
 if node is Button and label in node.text:return node
 for child in node.get_children():
  var result=button(child,label)
  if result!=null:return result
 return null
func click(control: Control):
 if control==null:return
 var parent=control.get_parent()
 while parent!=null:
  if parent is ScrollContainer:parent.ensure_control_visible(control)
  parent=parent.get_parent()
 await frames(2)
 for down in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=control.get_global_rect().get_center();root.push_input(event,true);await frames(1)
func capture(label: String):
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
 if folder=="" or DisplayServer.get_name()=="headless":return
 DirAccess.make_dir_recursive_absolute(folder);await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(10);game.close_modal();game.state.intro_seen=true;await frames(4)
 if game.state.factions.wars.is_empty():YinFactions.declare(game.state,"island","graveyard")
 game.show_quests();await frames();check("田园经营" not in texts(game.modal),"removed farming is not advertised")
 game.show_character("随从");await frames();check("收容" in texts(game.modal) and "出战不限" in texts(game.modal),"storage capacity is distinguished from unlimited deployment")
 game.show_factions();await frames()
 var support=button(game.modal,"支援守方")
 var scroll=game.modal.get_node("ModalCard/Layout/Scroll")
 check(support!=null and scroll.get_global_rect().encloses(support.get_global_rect()),"current war choice is visible on first screen")
 check("→" in texts(game.modal) and button(game.modal,"实力、领地")!=null,"war comes before optional numerical details")
 await capture("factions")
 game.show_equipment();await frames()
 var cards=[]
 for item in game.state.equipment:cards.append(button(game.modal,YinBalance.gear_name(item)))
 scroll=game.modal.get_node("ModalCard/Layout/Scroll")
 check(cards.size()==2 and cards.all(func(c):return c!=null and scroll.get_global_rect().encloses(c.get_global_rect())),"both opening weapons fit the first screen")
 await capture("equipment")
 await click(button(game.modal,"详情"));check("无需加工" in texts(game.modal) or "桃木" in texts(game.modal),"weapon introduction remains accessible in details")
 game.close_modal()
 var npc=game.state.villagers[3]
 var dialogue=YinNpcDialogue.new()
 check("没有记录" in dialogue.reply(game.state,npc,"我刚才击败了什么怪物"),"no invented kills when there are no combat records")
 var enemy=game.state.enemies.filter(func(e):return e.kind=="bone")[0];game.state.kill_enemy(enemy.id,Vector2(enemy.at[0],enemy.at[1]))
 check(YinBalance.MONSTERS.bone.name in dialogue.reply(game.state,npc,"我刚才击败了什么怪物"),"NPC queries actual recorded species instead of a limb tutorial")
 var other=game.state.enemies.filter(func(e):return e.kind=="archer")[0];other.dead=true
 check(YinBalance.MONSTERS.archer.name not in dialogue.reply(game.state,npc,"我刚才击败了什么怪物"),"unattributed world deaths are not invented as player kills")
 check("没有种田" in dialogue.reply(game.state,npc,"村西还能种田吗"),"NPC describes the current removed-farming rule")
 check("还不知道" in dialogue.reply(game.state,npc,"明天的午餐菜单是什么"),"unknown question gets an explicit fallback")
 var hint=YinGuidance30.chest_hint(game.state,game.player.position)
 check(not hint.is_empty() and hint.at==YinAdventure.chest_at(hint.id,true),"NPC uses real modern cache coordinates")
 game.show_chat(npc);await frames()
 var input=game.modal.find_child("NpcChatInput",true,false);input.text="附近宝箱在哪里";input.text_submitted.emit(input.text);await frames()
 check(not game.navigation_target.is_empty() and not game.navigation_target.route.is_empty(),"chat creates an actual walkable map route")
 await capture("npc")
 game.show_character("地图");await frames();await capture("map")
 var maps=game.modal.find_children("*","Control",true,false).filter(func(n):return n is YinMinimap)
 check(maps.size()==1 and maps[0].size.y>=190,"expanded map has room for legend and destination")
 if not maps.is_empty():
  var map=maps[0];var point=map.get_global_rect().position+map.point(YinContinent.HOME+Vector2(0,96))
  for down in [true,false]:
   var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event,true);await frames(1)
  check(game.navigation_target.name=="标记地点" and not game.navigation_target.route.is_empty(),"normal map click updates a physical route")
 game.close_modal()
 for id in ["road_supplies","road_bowl","road_tracks"]:
  var at=YinWorldDistricts.PLACES[id].at+Vector2(0,36);game.player.position=at;await frames()
  var path=game.world.path_to(YinContinent.HOME,at,Vector2(8,6));var previous=YinContinent.HOME;var clear=not path.is_empty()
  for step in path:clear=clear and game.world.clear_body_path(previous,step,Vector2(8,6));previous=step
  check(clear,"actual collision path reaches road event "+id)
  game.interact();await frames()
  check(game.modal!=null and game.state.world_echoes.has(id),"normal E opens road event "+id)
  var select=button(game.modal,"取行旅护甲") if id=="road_supplies" else button(game.modal,"路费") if id=="road_bowl" else button(game.modal,"循脚印")
  var before=game.state.equipment.size();await click(select)
  check(game.state.exploration_rewards.has(id),"choice is recorded once "+id)
  if id=="road_supplies":
   check(game.state.equipment.size()==before+1,"road cache grants actual armor")
   game.show_road_event30(id);await frames();check(button(game.modal,"取行旅护甲")==null,"no repeated armor farming")
  await capture(id)
  game.close_modal()
 check(FarmState.new().restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))),"road choices and attributable kills survive JSON save restore")
 if DisplayServer.get_name()!="headless":
  for at in [Vector2(5100,4216),Vector2(5552,2160)]:
   game.player.position=at;await frames(100)
   var cache=game.world.environment.ground_cache30
   check(cache!=null and cache.active and cache.chunks.size()<=cache.LIMIT,"bounded static cache fully covers actual camera")
   var sample=cache.chunks.values()[0].viewport.get_texture().get_image().get_pixel(100,100)
   check(sample.r>.02 and (sample.a<.01 or absf(sample.a-.5)<.01 or sample.a>.99),"cache preserves color while storing water classification in alpha")
   for attempt in range(120):
    if not cache.busy and cache.pending.is_empty():break
    await frames(1)
   var built=cache.builds;await frames(30)
   check(cache.builds==built and cache.chunks.values().all(func(c):return c.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED),"stationary scene does not rerender procedural terrain")
   await capture("cached-forest" if at.x<5500 else "cached-coast")
 for kind in YinMonsterArt.metadata():check(YinMonsterArt.metadata()[kind].get("art_revision")==30,"repainted independently detachable anatomy "+kind)
 print("POLISH30 RESULT ",checks," checks ",failures," failures");game.queue_free();await frames();quit(1 if failures else 0)
