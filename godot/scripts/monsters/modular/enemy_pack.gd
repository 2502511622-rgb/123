class_name YinEnemyPack
extends RefCounted
## Anatomy and legacy save aliases. Visual poses live in YinMonsterArt.
const PARTS=["body","head","arm_left","arm_right","leg_left","leg_right"]
const LIMBS=["arm_left","arm_right","leg_left","leg_right"]
const ALLOWED=["head","arm","leg","arm_left","arm_right","leg_left","leg_right"]
static func enabled(actor: Node) -> bool:
 return actor!=null and actor.get("game")!=null and actor.game.state.continent_ready and actor.get("record")!=null and actor.record.get("faction","")!="village"
static func missing(part: String,removed: Array) -> bool:
 return part in removed or (part.begins_with("arm_") and "arm" in removed) or (part.begins_with("leg_") and "leg" in removed)
static func anatomical(kind: String) -> Array:
 if kind in ["sogenbi","wraith"]:return []
 if kind=="chochin":return ["head"]
 if kind=="ippon_datara":return ["arm_left","arm_right","leg_right","head"]
 return LIMBS+["head"]
static func injured_arm(removed: Array) -> bool:
 return "arm" in removed or "arm_left" in removed or "arm_right" in removed
static func injured_leg(removed: Array) -> bool:
 return "leg" in removed or "leg_left" in removed or "leg_right" in removed
