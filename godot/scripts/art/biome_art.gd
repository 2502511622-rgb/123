class_name YinBiomeArt
extends RefCounted
const SIZES={"desert_hall":Vector2i(192,160),"desert_buddha":Vector2i(112,128),"desert_stupa":Vector2i(64,96),"desert_columns":Vector2i(112,88),"edo_shop":Vector2i(144,124),"edo_house":Vector2i(144,144),"broken_torii":Vector2i(112,112),"street_lantern":Vector2i(48,88),"mountain_crag":Vector2i(96,88),"dead_pine":Vector2i(112,120),"burial_cairn":Vector2i(80,72),"mountain_hut":Vector2i(112,112)}
static var cache: Dictionary={}
static func texture(id: String) -> Texture2D:
 if not cache.has(id):cache[id]=load("res://assets/biomes26/"+id+".png")
 return cache[id]
