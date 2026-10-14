class_name YinItemPickup
extends Node2D
var game: Node2D
var record: Dictionary
var age: float = 0
var retry: float = 0
func _process(delta: float) -> void:
	if game.modal != null: return
	age += delta
	retry = maxf(0, retry - delta)
	if age > 0.35 and retry <= 0 and position.distance_to(game.player.position) < 24:
		retry = 1
		if game.state.can_gain(record.item, record.count):
			game.state.set_container_count("bag", record.item, game.state.container_count("bag", record.item) + int(record.count))
			game.state.drops.erase(record)
			game.notify_action("拾取 %s ×%d。" % [YinItemCatalog.spec(record.item).display_name, record.count])
			queue_free()
		else: game.refresh("行囊已满，掉落物仍保留在原地。")
	queue_redraw()
func _draw() -> void:
	var offset: float = sin(age * 4) * 2
	var index: int = YinItemCatalog.IDS.find(record.item)
	draw_texture_rect_region(preload("res://assets/items.png"), Rect2(-8, -14 + offset, 16, 16), Rect2(index * 16, 0, 16, 16))
	draw_rect(Rect2(-7, 5, 14, 2), Color(0.1, 0.2, 0.2, 0.2))
	draw_string(ThemeDB.fallback_font, Vector2(-24, -18), YinItemCatalog.spec(record.item).display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("dfd1ac"))
