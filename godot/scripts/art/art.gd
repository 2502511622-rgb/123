class_name YinArt
extends RefCounted
const ROOT = "res://assets/art16/"
const HERO = preload("res://assets/art16/hero.png")
const VILLAGERS = preload("res://assets/art16/villagers.png")
const ENEMIES = preload("res://assets/monsters28/bone.png")
const SCENERY = preload("res://assets/art16/scenery.png")
static var cache: Dictionary = {}
static func texture(name_value: String) -> Texture2D:
	if YinWorldArt.REGIONS.has(name_value): return YinWorldArt.texture(name_value)
	if name_value == "npc": return YinActorArt.npc_texture(2)
	if not cache.has(name_value): cache[name_value] = load(ROOT + name_value + ".png")
	return cache[name_value]
static func enemy_row(kind: String) -> int:
	return YinBalance.MONSTERS.keys().find(kind)
static func terrain(zone: String) -> Texture2D:
	return texture("terrain_" + zone)
