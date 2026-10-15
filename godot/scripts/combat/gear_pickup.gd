class_name YinGearPickup
extends Node2D
var game: Node2D
var record: Dictionary
var age: float = 0
var retry: float = 0
func _process(delta: float) -> void:
 if game.modal != null: return
 age += delta
 retry = maxf(0, retry - delta)
 if age > 0.35 and retry <= 0 and position.distance_to(game.player.position) < 26:
  retry = 1
  if game.state.equipment.size() < 20:
   game.state.equipment.append(record.gear.duplicate(true))
   game.state.gear_drops.erase(record)
   game.notify_action("装备入手：" + YinBalance.gear_name(record.gear) + "。B 查看穿戴。")
   queue_free()
  else: game.refresh("装备位已满（20），掉落仍在地上；B 拆解备用装备。")
 queue_redraw()
func _draw() -> void:
 var tint: Color = YinBalance.COLORS[int(record.gear.quality)]
 draw_line(Vector2(0, -28), Vector2(0, 4), Color(tint, 0.35), 2)
 draw_texture_rect(YinBalance.icon(record.gear.weapon), Rect2(-12, -18, 24, 16), false)
 draw_string(ThemeDB.fallback_font, Vector2(-38, -30), YinBalance.WEAPONS[record.gear.weapon].name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, tint)
