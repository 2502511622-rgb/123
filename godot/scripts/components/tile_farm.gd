class_name YinTileFarm
extends Node2D
const FIELD = Vector2(320, 256)
var ground: TileMapLayer
var soil: TileMapLayer
var crops: TileMapLayer
var zone: String = "farm"
var water_frame: int = -1
func tileset(texture: Texture2D, columns: int, rows: int) -> TileSet:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(16, 16)
	for y in range(rows):
		for x in range(columns): atlas.create_tile(Vector2i(x, y))
	var set := TileSet.new()
	set.tile_size = Vector2i(16, 16)
	set.add_source(atlas, 0)
	return set
func layer(name_text: String, set: TileSet, depth: int, at: Vector2) -> TileMapLayer:
	var node := TileMapLayer.new()
	node.name = name_text
	node.tile_set = set
	node.scale = Vector2(2, 2)
	node.position = at
	node.z_index = depth
	add_child(node)
	return node
func build(zone_name: String) -> void:
	zone = zone_name
	var terrain := tileset(preload("res://assets/tiles.png"), 16, 1)
	ground = layer("Ground", terrain, -3, Vector2.ZERO)
	soil = layer("TilledAndWatered", terrain, -2, FIELD)
	crops = layer("CropStages", tileset(preload("res://assets/crops.png"), 6, 4), -1, FIELD - Vector2(0, 4))
	for y in range(40 if zone == "forest" else 20):
		for x in range(60 if zone == "forest" else 30):
			var id: int = (x * 7 + y * 11) % 8
			if y in [7, 8] or (x == 8 and y >= 6 and y <= 17) or (x >= 22 and x <= 25 and y >= 6 and y <= 11): id = 10
			if x in [20, 21]: id = 11 if zone == "farm" else 8
			if (x * 13 + y * 7) % 31 == 0 and id < 8: id = 14
			if zone in ["hall", "shop"]: id = 10
			if zone == "forest":
				id = (x * 7 + y * 11) % 8
				if x == 10 or y == 32 or y in [17, 18]: id = 10
				if x in [30, 31]: id = 11
			ground.set_cell(Vector2i(x, y), 0, Vector2i(id, 0))
func refresh(state: FarmState, time: float) -> void:
	if zone != "farm": return
	var frame: int = int(time * 2) % 3
	if frame != water_frame:
		water_frame = frame
		for y in range(20):
			for x in [20, 21]: ground.set_cell(Vector2i(x, y), 0, Vector2i(11 + frame, 0))
	for i in range(state.plots.size()):
		var cell := Vector2i(i % 8, int(i / 8))
		var p: Dictionary = state.plots[i]
		soil.set_cell(cell, 0, Vector2i(9 if p.watered else (8 if p.tilled else 15), 0))
		if p.crop == "": crops.erase_cell(cell)
		else:
			var row: int = ["candle", "vine", "gourd", "rice"].find(p.crop)
			var stage: int = 5 if p.growth >= FarmState.CROPS[p.crop].growth_days else mini(4, p.growth + 1)
			crops.set_cell(cell, 0, Vector2i(stage, row))
func plot_at(at: Vector2) -> int:
	if zone != "farm" or soil == null: return -1
	var cell: Vector2i = soil.local_to_map(soil.to_local(at))
	return cell.y * 8 + cell.x if cell.x >= 0 and cell.x < 8 and cell.y >= 0 and cell.y < 6 else -1
func plot_center(index: int) -> Vector2:
	return soil.to_global(soil.map_to_local(Vector2i(index % 8, int(index / 8))))
