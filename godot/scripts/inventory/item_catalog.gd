class_name YinItemCatalog
extends RefCounted
const IDS = ["candle_seeds", "vine_seeds", "gourd_seeds", "rice_seeds", "candle", "vine", "gourd", "rice", "oil", "talisman", "bone", "ash", "wood", "stone", "paper_lamp", "ward_stake"]
static var entries: Dictionary = {}
static func spec(id: String) -> YinItemSpec:
	if not IDS.has(id): return null
	if not entries.has(id): entries[id] = load("res://resources/items/%s.tres" % id)
	return entries[id]
