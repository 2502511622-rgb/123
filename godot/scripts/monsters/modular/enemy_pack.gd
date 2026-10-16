class_name YinEnemyPack
extends RefCounted
## Shared specification used by the offline baker and the live modular skeleton.
const SIZE=64
const IDS=["drowned","skeleton","tengu","hungry","rakshasa"]
const PARTS=["body","head","arm_left","arm_right","leg_left","leg_right"]
const LIMBS=["arm_left","arm_right","leg_left","leg_right"]
const ALLOWED=["head","arm","leg","arm_left","arm_right","leg_left","leg_right"]
const PIVOTS={"body":Vector2(32,40),"head":Vector2(32,22),"arm_left":Vector2(22,25),"arm_right":Vector2(42,25),"leg_left":Vector2(27,42),"leg_right":Vector2(37,42)}
const PALETTE=["171f2b","263344","3b4b56","56676a","829391","b6b5a1","e0d1ad","63534c","94705b","b39070","532f38","834348","b26256","c69576","334b50","4b6e69","789183","202b38","394259","65627b","25292b","55504b","8b8170","c6b79b"]
static var textures: Dictionary={}
static func enabled(actor: Node) -> bool:
 return actor!=null and actor.get("game")!=null and actor.game.state.continent_ready and actor.get("record")!=null and actor.record.get("faction","")!="village"
static func pack_for(kind: String) -> String:
 if kind in ["water","kappa","sunken","tide_boss"]:return "drowned"
 if kind in ["daitengu","itsumade","archer","gunner"]:return "tengu"
 if kind in ["gaki","hungry_ghost","wraith","sogenbi","chochin","lantern","ghost","opera_boss"]:return "hungry"
 if kind in ["rakshasa","kumbhanda","asura","yaksha","ryomen_sukuna","brute","jorogumo"]:return "rakshasa"
 return "skeleton"
static func texture(pack: String) -> Texture2D:
 if not textures.has(pack):textures[pack]=load("res://assets/enemy_packs/"+pack+"/atlas.png")
 return textures[pack]
static func region(index: int) -> Rect2:
 return Rect2(Vector2(index%8,index/8)*SIZE,Vector2.ONE*SIZE)
static func missing(part: String,removed: Array) -> bool:
 return part in removed or (part.begins_with("arm_") and "arm" in removed) or (part.begins_with("leg_") and "leg" in removed)
static func anatomical(kind: String) -> Array:
 if kind in ["sogenbi","wraith"]:return []
 if kind=="chochin":return ["head"]
 if kind=="ippon_datara":return ["arm_left","arm_right","leg_right","head"]
 return LIMBS+["head"]
static func transform_for(part: String,clock: float,moving: bool,attack: bool,hit: int=-1) -> Transform2D:
 var step=sin(clock*10.0) if moving else 0.0
 var bob=-absf(step)*1.2 if moving else sin(clock*2)*0.8
 var pivot: Vector2=PIVOTS[part]-Vector2(32,61)
 var angle=0.0
 if part.begins_with("leg_"):
  var side=-1.0 if part.ends_with("left") else 1.0
  angle=side*step*0.18;pivot.y-=maxf(0,side*step)*2
  if moving:pivot.x+=cos(clock*10.0)*side*0.6
 elif part.begins_with("arm_"):
  var side=-1.0 if part.ends_with("left") else 1.0
  angle=-side*step*0.13+(side*0.58 if attack else sin(clock*2+0.8)*side*0.025)
 elif part=="head":angle=sin(clock*2+0.6)*0.035
 if hit>=0:
  pivot+=Vector2([-3.0,2.0,0.0][mini(hit,2)],[-1.0,0.0,0.0][mini(hit,2)])
  angle+=[-0.12,0.06,0.0][mini(hit,2)]
 pivot.y+=bob
 return Transform2D(angle,pivot)

static func injured_arm(removed: Array) -> bool:
 return "arm" in removed or "arm_left" in removed or "arm_right" in removed
static func injured_leg(removed: Array) -> bool:
 return "leg" in removed or "leg_left" in removed or "leg_right" in removed
