class_name YinMonsterArt
extends RefCounted
const SIZE=96
const PARTS=["body","head","arm_left","arm_right","leg_left","leg_right"]
static var cache: Dictionary={}
static var data: Dictionary={}
static func metadata() -> Dictionary:
 if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/monsters27/manifest.json"))
 return data
static func texture(kind: String) -> Texture2D:
 if not cache.has(kind):cache[kind]=load("res://assets/monsters27/"+kind+".png")
 return cache[kind]
static func region(index: int) -> Rect2:
 return Rect2(Vector2(index%8,index/8)*96,Vector2(96,96))
static func pivot(kind: String,frame: int,part: String) -> Vector2:
 var p=metadata()[kind].pivots[frame][PARTS.find(part)]
 return Vector2(p[0],p[1])
static func frame_at(clock: float,moving: bool,attack: bool) -> int:
 if attack:return 3
 return [0,1,0,2][int(clock*10)%4] if moving else 0
