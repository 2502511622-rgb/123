class_name YinTerrainResource
extends StaticBody2D
var state: FarmState
var world: FarmWorld
var key: String
var kind: String
var world_rect: Rect2
var health_receiver: YinHealthReceiver
var required_tool: int = 4
func _ready() -> void:
	if not state.terrain.has(key): state.terrain[key] = {"hp": 3}
	health_receiver = YinHealthReceiver.new()
	health_receiver.bind_record(state.terrain[key])
	add_child(health_receiver)
	add_to_group("terrain_resources")
func strike(tool: int) -> bool:
	if tool != required_tool or state.terrain[key].hp <= 0: return false
	health_receiver.apply(1, "tool")
	world.effect(position, Color("b7b68d"))
	if state.terrain[key].hp == 0:
		world.obstacles.erase(world_rect)
		world.loot_requested.emit("wood" if kind == "tree" else "stone", 2, position)
		queue_free()
	return true
