class_name YinSceneRouter
extends Node
signal scene_changed(zone: String, world: Node2D)
const ROUTES = {
	"sunken": preload("res://scenes/maps/sunken.tscn"),
	"theatre": preload("res://scenes/maps/theatre.tscn"),
	"forest": preload("res://scenes/maps/forest.tscn"),
	"farm": preload("res://scenes/maps/farm.tscn"),
	"graveyard": preload("res://scenes/maps/graveyard.tscn"),
	"hall": preload("res://scenes/maps/hall.tscn"),
	"shop": preload("res://scenes/maps/shop.tscn")
}
var levels: Node2D
var current: FarmWorld
func bind(level_root: Node2D) -> void:
	levels = level_root
func install(zone: String, data: FarmState) -> FarmWorld:
	if not ROUTES.has(zone) or levels == null: return null
	var next: FarmWorld = ROUTES[zone].instantiate()
	next.state = data
	if is_instance_valid(current):
		current.process_mode = Node.PROCESS_MODE_DISABLED
		levels.remove_child(current)
		current.queue_free()
	current = next
	levels.add_child(next)
	scene_changed.emit(zone, next)
	return next
func spawn(entry: String, fallback: Vector2) -> Vector2:
	if not is_instance_valid(current): return fallback
	var point: Node2D = current.get_node_or_null("SpawnPoints/" + entry)
	return point.position if point != null else fallback
