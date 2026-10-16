class_name YinEnemyPack
extends RefCounted
## Anatomy and legacy save aliases. Visual poses live in YinMonsterArt.
const PARTS=["body","head","arm_left","arm_right","leg_left","leg_right"]
const LIMBS=["arm_left","arm_right","leg_left","leg_right"]
const ALLOWED=["head","arm","leg","arm_left","arm_right","leg_left","leg_right"]
static func enabled(actor: Node) -> bool:
 return actor!=null and actor.get("game")!=null and actor.game.state.continent_ready and actor.get("record")!=null and actor.record.get("faction","")!="village"
static func missing(part: String,removed: Array) -> bool:
 return part in removed or (part=="arm_right" and "arm" in removed) or (part=="leg_right" and "leg" in removed)
static func anatomical(kind: String) -> Array:
 if kind in ["sogenbi","wraith"]:return []
 if kind=="chochin":return ["arm_left","arm_right","leg_left","leg_right","head"]
 if kind=="itsumade":return ["arm_left","arm_right","head"]
 if kind=="ippon_datara":return ["arm_left","arm_right","leg_right","head"]
 return LIMBS+["head"]
static func injured_arm(removed: Array) -> bool:
 return "arm" in removed or "arm_left" in removed or "arm_right" in removed
static func injured_leg(removed: Array) -> bool:
 return "leg" in removed or "leg_left" in removed or "leg_right" in removed

static func movement_factor(kind: String,removed: Array) -> float:
 var native=anatomical(kind).filter(func(p):return p.begins_with("leg_"))
 if native.is_empty():return 1.0
 var missing_legs=native.filter(func(p):return missing(p,removed)).size()
 if missing_legs>=native.size():return .24
 return .62 if missing_legs>0 else 1.0
