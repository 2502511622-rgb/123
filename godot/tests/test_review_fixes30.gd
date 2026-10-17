extends SceneTree
var game
var checks=0
var failures=0
func _initialize():OS.set_environment("YINTIAN_LEGACY_MAPS","");call_deferred("run")
func frames(n=4):
 for i in range(n):await physics_frame
func check(ok: bool,label: String):
 checks+=1;print("REVIEW30 ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func find(node: Node,label: String) -> Button:
 if node is Button and label in node.text:return node
 for child in node.get_children():
  var found=find(child,label)
  if found!=null:return found
 return null
func click(control: Button):
 if control==null:check(false,"required actual button exists");return
 var scroll=game.modal.get_node("ModalCard/Layout/Scroll");scroll.ensure_control_visible(control);await frames()
 for down in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=control.get_global_rect().get_center();event.pressed=down;root.push_input(event,true);await frames(1)
 await frames()
func capture(label):
 var folder=OS.get_environment("YINTIAN_CAPTURE_DIR")
 if folder=="" or DisplayServer.get_name()=="headless":return
 DirAccess.make_dir_recursive_absolute(folder);await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func fits(node: Node,bounds: Rect2) -> bool:
 if node is Label and (node.get_global_rect().position.x<bounds.position.x-1 or node.get_global_rect().end.x>bounds.end.x+1):return false
 for child in node.get_children():
  if not fits(child,bounds):return false
 return true
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames(10);game.close_modal();game.state.intro_seen=true
 game.show_road_event30("road_supplies");await frames()
 var box=game.modal.get_node("ModalCard/Layout/Scroll/Content")
 game.paragraph(box,"长段落测试：道路、荒岭与森林中的说明文字必须在当前窗口宽度内换行。".repeat(8))
 await frames()
 var scroll=game.modal.get_node("ModalCard/Layout/Scroll")
 check(scroll.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED and not scroll.get_h_scroll_bar().visible,"event has no horizontal scroll")
 check(fits(box,scroll.get_global_rect()),"all long description and paragraph rectangles remain within viewport width")
 check(box.get_child(0).get_line_count()>1,"original road description actually wraps instead of clipping")
 await capture("wrapped-event")
 # Full inventory must not consume a one-time choice.
 var starter=game.state.equipment.duplicate(true)
 while game.state.equipment.size()<20:game.state.grant_gear(starter[0].weapon)
 game.show_road_event30("road_supplies");await frames();await click(find(game.modal,"取行旅护甲"))
 check(game.state.equipment.size()==20 and not game.state.exploration_rewards.has("road_supplies"),"full inventory cannot consume the armor choice")
 game.state.equipment=starter
 # Remove long fixture and exercise real road reward button.
 game.show_road_event30("road_supplies");await frames()
 var original_weapon=game.state.equipped_gear
 await click(find(game.modal,"取行旅护甲"))
 var armor=game.state.equipment.back()
 check(game.state.exploration_rewards.has("road_supplies") and armor.weapon=="armor","actual road choice grants and persists armor")
 check(game.state.equipped_armor!=armor.id,"preview leaves current armor untouched")
 var equip=find(game.modal,"装备并继续")
 scroll=game.modal.get_node("ModalCard/Layout/Scroll")
 check(equip!=null and scroll.get_global_rect().encloses(equip.get_global_rect()),"direct equip action is on first reward screen")
 await capture("armor-reward")
 await click(equip)
 check(game.modal==null and game.state.equipped_armor==armor.id and game.state.equipped_gear==original_weapon,"armor equip closes preview without changing held weapon")
 game.show_road_event30("road_supplies");await frames();check(find(game.modal,"取行旅护甲")==null,"returning cannot duplicate reward")
 game.close_modal();game.state.zone="farm";YinFirstJourney.start(game.state)
 var enemies=game.state.enemies.filter(func(e):return e.zone=="graveyard" and not e.dead and not e.has("war_id"))
 for i in range(2):game.state.kill_enemy(enemies[i].id,Vector2(enemies[i].at[0],enemies[i].at[1]))
 var count=game.state.equipment.size();var money=game.state.money
 game.show_quests();await frames();await click(find(game.modal,"复命 · 领取银剑"))
 var silver=game.state.equipment.back()
 check(silver.weapon=="silver_sword" and game.state.equipment.size()==count+1 and game.state.money==money+35,"real quest claim grants exactly one silver sword and money")
 check(game.state.equipped_gear==original_weapon,"silver comparison does not automatically replace weapon")
 equip=find(game.modal,"装备并继续");scroll=game.modal.get_node("ModalCard/Layout/Scroll")
 check(equip!=null and scroll.get_global_rect().encloses(equip.get_global_rect()),"silver equip is visible without scrolling")
 check(fits(scroll.get_child(0),scroll.get_global_rect()),"reward details wrap within current width")
 await capture("silver-reward")
 await click(find(game.modal,"暂存行囊"))
 check(game.state.equipped_gear==original_weapon and game.state.quests.first_watch.claimed,"postponing retains reward without forcing equip")
 game.show_quests();await frames();check(find(game.modal,"复命 · 领取银剑")==null and game.state.money==money+35,"reopening quest cannot duplicate payout")
 game.show_reward_gear30(silver.id,"查看已领取的银剑",game.show_quests);await frames();await click(find(game.modal,"装备并继续"))
 check(game.state.weapon_slots.melee==silver.id and game.player.held_item=="silver_sword" and YinFirstJourney.guide(game.state).is_empty(),"direct equip updates slot, held weapon and tutorial objective")
 var saved=FarmState.new();check(saved.restore(JSON.parse_string(JSON.stringify(game.state.snapshot()))) and saved.equipped_armor==armor.id and saved.weapon_slots.melee==silver.id,"both equipped rewards survive JSON restore")
 # Visual probe: actual living enemy, no substituted image or removed limb.
 game.close_modal();game.player.position=Vector2(4200,3050);await frames(4)
 var visible_enemy=null
 for e in get_nodes_in_group("enemies"):
  if not e.record.dead and e.position.distance_to(game.player.position)<240:visible_enemy=e;break
 if visible_enemy!=null:
  game.player.position=visible_enemy.position+Vector2(55,40)
  game.player.get_node("Camera2D").reset_smoothing();game.player.get_node("Camera2D").force_update_scroll();await frames(20)
  check(visible_enemy.material.get_shader_parameter("readability")!=null and visible_enemy.material.get_shader_parameter("readability")>.5,"nearby hostile uses contrast treatment")
  check(visible_enemy.material.get_shader_parameter("contour")!=null and visible_enemy.material.get_shader_parameter("contour")>=.38,"nearby hostile retains colored edge")
  await capture("combat-readability")
 else:check(false,"living enemy available for graphical combat probe")
 print("REVIEW30 RESULT ",checks," checks ",failures," failures");game.queue_free();await frames();quit(1 if failures else 0)
