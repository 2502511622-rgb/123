class_name YinMonsterArt
extends RefCounted
const SIZE=96
const PARTS=["body","head","arm_left","arm_right","leg_left","leg_right"]
const WALK_KEYS=[Vector3(0,0,0),Vector3(.65,-2,.10),Vector3(1,-3,.17),Vector3(.5,-1,.08),Vector3(0,0,0),Vector3(-.65,0,-.10),Vector3(-1,0,-.17),Vector3(-.5,0,-.08)]
const ATTACK_KEYS=[Vector3(0,0,0),Vector3(-.42,-2,-.14),Vector3(-.68,-3,-.20),Vector3(1.05,3,.18),Vector3(.52,1,.08),Vector3(0,0,0)]
static var cache: Dictionary={}
static var data: Dictionary={}
static func metadata() -> Dictionary:
 if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/monsters28/manifest.json"))
 return data
static func texture(kind: String) -> Texture2D:
 if not cache.has(kind):cache[kind]=load("res://assets/monsters28/"+kind+".png")
 return cache[kind]
static func region(index: int) -> Rect2:
 return Rect2(Vector2(index%8,index/8)*96,Vector2(96,96))
static func pivot(kind: String,frame: int,part: String) -> Vector2:
 var p=metadata()[kind].pivots[frame][PARTS.find(part)]
 return Vector2(p[0],p[1])
static func frame_at(_clock: float,_moving: bool,_attack: bool) -> int:
 # A real joint rig animates complete parts; it never selects cropped full-body poses.
 return 0

static func walk_key(phase: float) -> Vector3:
 var keys=WALK_KEYS
 var p=fposmod(phase,TAU)/TAU*8;var i=int(p);var f=smoothstep(0,1,p-i)
 return keys[i].lerp(keys[(i+1)%8],f)
static func attack_key(progress: float) -> Vector3:
 var keys=ATTACK_KEYS
 var p=clampf(progress,0,.99999)*5;var i=int(p)
 return keys[i].lerp(keys[mini(i+1,5)],smoothstep(0,1,p-i))
static func joint_pose(kind: String,part: String,phase: float,moving: bool,action: Vector3,hit: int=-1,aim: float=0) -> Transform2D:
 var base=pivot(kind,0,part)-Vector2(48,90);var gait=walk_key(phase) if moving else Vector3.ZERO
 var angle=0.0;var step_sign=-1.0 if part.ends_with("left") else 1.0
 if part.begins_with("leg_"):
  var foot=walk_key(phase+(PI if step_sign<0 else 0)) if moving else Vector3.ZERO
  base+=Vector2(foot.x*2,foot.y);angle=foot.z*.6
 elif part.begins_with("arm_"):
  angle=-gait.z*step_sign+action.x*(1.0 if step_sign>0 else -.35)
  if part=="arm_right":angle+=aim*clampf(absf(action.x),0,1)
  base+=Vector2(action.y*.25,0)
 elif part=="body":
  angle=action.z*.30;base+=Vector2(action.y*.35,-absf(gait.x)*.65)
 elif part=="head":base+=Vector2(action.y*.20,-absf(gait.x)*.4);angle=-action.z*.1
 if hit>=0:base.x+=[-3.0,2.0,0.0][mini(hit,2)]
 return Transform2D(angle,base)

static func action_for(motion: Dictionary,attack: bool) -> float:
 var state: String=motion.get("state","");var value=float(motion.get("action",0))
 if state=="anticipation":return clampf((-value-.2)/.6,0,1)*.4
 if state=="strike":return .4+clampf(1-value,0,1)*.24
 if state=="recover":return .64+clampf(1-value/.2,0,1)*.36
 return .55 if attack else 1.0

static func visual_height(kind: String) -> float:
 return float(metadata()[kind].get("height",58))
