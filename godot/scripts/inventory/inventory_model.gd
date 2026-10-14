class_name YinInventoryModel
extends RefCounted
signal changed
const CAPACITY = 24
var state: FarmState
var container: String = "bag"
var overflow: bool = false
func _init(data: FarmState = null, location: String = "bag") -> void:
	state = data
	container = location
func layout_key() -> String:
	return "bag_slots" if container == "bag" else "chest_slots"
func counts() -> Dictionary:
	var result: Dictionary = {}
	for id in YinItemCatalog.IDS:
		result[id] = int(state.container_count(container, id))
	return result
func write_counts(values: Dictionary) -> void:
	for id in YinItemCatalog.IDS: state.set_container_count(container, id, int(values.get(id, 0)))
func slots() -> Array:
	return state.get(layout_key())
static func empty() -> Dictionary:
	return {"id": "", "count": 0}
func sync() -> bool:
	if state == null: return false
	var remaining: Dictionary = counts()
	var next: Array = slots().duplicate(true)
	while next.size() < CAPACITY: next.append(empty())
	for i in range(CAPACITY):
		var cell: Dictionary = next[i]
		if cell.id == "" or not remaining.has(cell.id):
			next[i] = empty()
			continue
		var keep: int = mini(int(cell.count), mini(int(remaining[cell.id]), YinItemCatalog.spec(cell.id).max_stack))
		remaining[cell.id] -= keep
		next[i] = {"id": cell.id, "count": keep} if keep > 0 else empty()
	# Preserve deliberate splitting while filling remaining stacks.
	for id in YinItemCatalog.IDS:
		var limit: int = YinItemCatalog.spec(id).max_stack
		for cell in next:
			if cell.id == id and remaining[id] > 0:
				var add: int = mini(remaining[id], limit - int(cell.count))
				cell.count += add
				remaining[id] -= add
		for i in range(CAPACITY):
			if next[i].id == "" and remaining[id] > 0:
				var add: int = mini(remaining[id], limit)
				next[i] = {"id": id, "count": add}
				remaining[id] -= add
	if remaining.values().any(func(value): return value > 0):
		overflow = true
		state.set(layout_key(), next)
		return false
	overflow = false
	state.set(layout_key(), next)
	return true
func move(index: int, destination: YinInventoryModel, target: int, amount: int = -1) -> bool:
	if not sync() or not destination.sync(): return false
	if index < 0 or index >= CAPACITY or target < 0 or target >= CAPACITY: return false
	if state == destination.state and container == destination.container and index == target: return false
	var from: Array = slots().duplicate(true)
	var to: Array = from if container == destination.container and state == destination.state else destination.slots().duplicate(true)
	var a: Dictionary = from[index]
	var b: Dictionary = to[target]
	if a.id == "" or amount == 0: return false
	var count: int = int(a.count) if amount < 0 else mini(amount, int(a.count))
	if b.id == "" or b.id == a.id:
		count = mini(count, YinItemCatalog.spec(a.id).max_stack - int(b.count))
		if count <= 0: return false
		to[target] = {"id": a.id, "count": int(b.count) + count}
		a.count -= count
		if a.count == 0: from[index] = empty()
	else:
		if amount >= 0 and count < int(a.count): return false
		from[index] = b.duplicate()
		to[target] = a.duplicate()
	state.set(layout_key(), from)
	destination.state.set(destination.layout_key(), to)
	apply_layout_counts()
	if container != destination.container or state != destination.state: destination.apply_layout_counts()
	changed.emit()
	destination.changed.emit()
	return true
func apply_layout_counts() -> void:
	var values: Dictionary = {}
	for id in YinItemCatalog.IDS: values[id] = 0
	for cell in slots():
		if cell.id != "": values[cell.id] += int(cell.count)
	write_counts(values)
func compact() -> bool:
	state.set(layout_key(), [])
	var success: bool = sync()
	changed.emit()
	return success
static func fits(values: Dictionary) -> bool:
	var used: int = 0
	for id in YinItemCatalog.IDS:
		used += int(ceil(float(values.get(id, 0)) / YinItemCatalog.spec(id).max_stack))
	return used <= CAPACITY
