class_name YinWorldDetailArt
extends RefCounted
const SIZES={"stone_steps":Vector2i(80,48),"bell":Vector2i(56,52),"scrolls":Vector2i(72,64),"basin":Vector2i(64,42),"urns":Vector2i(48,44),"rubble_wall":Vector2i(72,40),"stall":Vector2i(80,72),"crates":Vector2i(52,44),"banner":Vector2i(40,72),"footbridge":Vector2i(112,64),"cart":Vector2i(64,52),"umbrellas":Vector2i(48,36),"offering":Vector2i(56,44),"swords":Vector2i(48,56),"crow_post":Vector2i(32,52),"rope":Vector2i(80,48),"wood_steps":Vector2i(80,56),"cave":Vector2i(104,88),"village_well":Vector2i(64,72),"noodles":Vector2i(80,64),"tea":Vector2i(64,40),"laundry":Vector2i(96,56),"firewood":Vector2i(48,40),"jetty":Vector2i(104,64)}
static var cache: Dictionary={}
static func texture(id: String) -> Texture2D:
 if not cache.has(id):cache[id]=load("res://assets/districts27/"+id+".png")
 return cache[id]
