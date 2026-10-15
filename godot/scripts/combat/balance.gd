class_name YinBalance
extends RefCounted
const WEAPONS = {
 "prajna": {"name": "文殊般若剑", "damage": 25, "interval": 0.48, "magazine": 0, "reload": 0.0, "ammo": "", "speed": 0, "spread": 0.0, "range": 88},
 "sword": {"name": "桃木剑", "damage": 15, "interval": 0.32, "magazine": 0, "reload": 0.0, "ammo": "", "speed": 0, "spread": 0.0, "range": 49},
 "pistol": {"name": "手枪", "damage": 19, "interval": 0.28, "magazine": 8, "reload": 1.0, "ammo": "light_ammo", "speed": 700, "spread": 0.018, "range": 650},
 "smg": {"name": "冲锋枪", "damage": 9, "interval": 0.09, "magazine": 24, "reload": 1.4, "ammo": "light_ammo", "speed": 750, "spread": 0.09, "range": 560},
 "rifle": {"name": "步枪", "damage": 31, "interval": 0.2, "magazine": 12, "reload": 1.6, "ammo": "rifle_ammo", "speed": 1000, "spread": 0.008, "range": 1000},
 "whip": {"name": "鞭子", "damage": 13, "interval": 0.48, "magazine": 0, "reload": 0.0, "ammo": "", "speed": 0, "spread": 0.0, "range": 112},
 "silver_sword": {"name": "银剑", "damage": 24, "interval": 0.4, "magazine": 0, "reload": 0.0, "ammo": "", "speed": 0, "spread": 0.0, "range": 57},
 "revolver": {"name": "左轮", "damage": 38, "interval": 0.48, "magazine": 6, "reload": 1.7, "ammo": "light_ammo", "speed": 900, "spread": 0.01, "range": 820},
 "gatling": {"name": "加特林", "damage": 7, "interval": 0.055, "magazine": 80, "reload": 3.2, "ammo": "rifle_ammo", "speed": 800, "spread": 0.12, "range": 760},
 "spellbook": {"name": "魔法书", "damage": 26, "interval": 0.6, "magazine": 0, "reload": 0.0, "ammo": "", "speed": 340, "spread": 0.0, "range": 640, "energy": 7},
 "curse_doll": {"name": "咒术娃娃", "damage": 18, "interval": 0.9, "magazine": 0, "reload": 0.0, "ammo": "", "speed": 0, "spread": 0.0, "range": 220, "energy": 9},
 "ipetam": {"name": "伊佩塔姆", "damage": 28, "interval": 0.38, "magazine": 0, "reload": 0.0, "ammo": "", "speed": 0, "spread": 0.0, "range": 76},
 "armor": {"name": "镇煞护甲", "damage": 0, "interval": 0.0, "magazine": 0, "reload": 0.0, "ammo": "", "speed": 0, "spread": 0.0, "range": 0}
}
const MELEE = ["prajna", "ipetam", "sword", "whip", "silver_sword"]
const GUNS = ["pistol", "smg", "rifle", "revolver", "gatling"]
const MAGIC = ["spellbook", "curse_doll"]
const ICON_ORDER = ["sword", "pistol", "smg", "rifle", "armor", "whip", "silver_sword", "revolver", "gatling", "spellbook", "curse_doll", "ipetam", "prajna"]
const ELEMENTS = ["burn", "freeze", "lightning"]
const ELEMENT_NAMES = {"burn": "燃烧", "freeze": "冰冻", "lightning": "闪电"}
const ELEMENT_COLORS = {"burn": Color("f4a261"), "freeze": Color("91d8ee"), "lightning": Color("c4a7ef")}
const QUALITY = ["凡品", "灵纹", "珍品", "异宝"]
const COLORS = [Color("c5c8b5"), Color("84bdda"), Color("e5c477"), Color("e7a46e")]
const MONSTERS = {
 "hungry_ghost": {"name": "饿鬼", "hp": 100, "damage": 13, "speed": 39, "pattern": "hunger", "armor": 2},
 "wraith": {"name": "幽魂", "hp": 75, "damage": 12, "speed": 36, "pattern": "ethereal", "armor": 0},
 "rakshasa": {"name": "罗刹", "hp": 140, "damage": 19, "speed": 48, "pattern": "mirage", "armor": 8},
 "kumbhanda": {"name": "鸠槃茶", "hp": 155, "damage": 14, "speed": 29, "pattern": "nightmare", "armor": 6},
 "asura": {"name": "阿修罗", "hp": 880, "damage": 26, "speed": 43, "pattern": "six_arms", "armor": 18},
 "yaksha": {"name": "夜叉", "hp": 1040, "damage": 28, "speed": 54, "pattern": "guardian", "armor": 20},
 "kappa": {"name": "河童", "hp": 90, "damage": 12, "speed": 37, "pattern": "river", "armor": 6},
 "chochin": {"name": "提灯妖怪", "hp": 65, "damage": 10, "speed": 40, "pattern": "tongue", "armor": 0},
 "ippon_datara": {"name": "一本踏鞴", "hp": 145, "damage": 22, "speed": 42, "pattern": "hammer", "armor": 12},
 "jorogumo": {"name": "络新妇", "hp": 115, "damage": 13, "speed": 39, "pattern": "web", "armor": 4},
 "sogenbi": {"name": "丛原火", "hp": 80, "damage": 14, "speed": 33, "pattern": "wicked_flame", "armor": 2},
 "itsumade": {"name": "以津真天", "hp": 580, "damage": 19, "speed": 35, "pattern": "lament", "armor": 12},
 "daitengu": {"name": "大天狗", "hp": 700, "damage": 23, "speed": 48, "pattern": "gale", "armor": 16},
 "ryomen_sukuna": {"name": "两面宿傩", "hp": 900, "damage": 27, "speed": 43, "pattern": "dual", "armor": 20},
 "water": {"name": "担水尸", "hp": 50, "damage": 9, "speed": 29, "pattern": "melee", "armor": 0},
 "bone": {"name": "掘土骨", "hp": 42, "damage": 9, "speed": 29, "pattern": "melee", "armor": 0},
 "archer": {"name": "吐骨骷", "hp": 58, "damage": 10, "speed": 27, "pattern": "fan", "armor": 3},
 "lantern": {"name": "追灯鬼", "hp": 65, "damage": 8, "speed": 32, "pattern": "ring", "armor": 2},
 "gunner": {"name": "纸铳兵", "hp": 72, "damage": 11, "speed": 25, "pattern": "burst", "armor": 5},
 "brute": {"name": "山魈", "hp": 110, "damage": 16, "speed": 46, "pattern": "melee", "armor": 8},
 "well_boss": {"name": "井中龙婆", "hp": 420, "damage": 20, "speed": 30, "pattern": "tide", "armor": 12},
 "opera_boss": {"name": "无面伶王", "hp": 380, "damage": 19, "speed": 44, "pattern": "opera", "armor": 8},
 "boss": {"name": "棺中客", "hp": 520, "damage": 23, "speed": 39, "pattern": "boss", "armor": 0}
}
static func level(cultivation: int) -> int:
 return mini(20, 1 + int(cultivation / 80))
static func damage(base: int, actor_level: int, gear: Dictionary = {}, armor: int = 0) -> int:
 if base <= 0: return 0
 var tier: int = int(gear.get("tier", 1))
 var bonus: int = int(gear.get("bonus", 0))
 var growth: int = 2 * (clampi(actor_level, 1, 20) - 1) if gear.get("weapon") == "prajna" else (2 * (artifact_level(gear) - 1) if gear.get("weapon") == "ipetam" else 0)
 var raw: float = (base + growth) * (1 + 0.07 * (tier - 1) + 0.02 * (actor_level - 1)) * (1 + bonus / 100.0)
 return maxi(1, roundi(raw * 100.0 / (100 + maxi(0, armor))))
static func make_gear(id: int, weapon: String, tier: int = 1, quality: int = 0) -> Dictionary:
 if weapon in ["ipetam", "prajna"]: quality = 3
 var affixes: Array = []
 # Stable innate rolls: purchased, granted and dropped gear use one generation path.
 if weapon not in ["armor", "ipetam", "prajna"]:
  var first: String = "crit" if (id + tier) % 2 == 0 else "bleed"
  affixes.append({"id": first, "value": 8 + quality * 4 if first == "crit" else 3 + mini(quality, 3)})
  if quality >= 2:
   affixes.append({"id": "bleed" if first == "crit" else "crit", "value": 4 if first == "crit" else 16})
 var result := {"id": id, "weapon": weapon, "tier": tier, "quality": quality, "bonus": quality * 8, "magazine": 0, "affixes": affixes, "enchantment": ELEMENTS[randi_range(0, 2)] if weapon not in ["armor", "ipetam", "prajna"] else ""}
 if weapon == "prajna":
  result.enchantment = "all"
  result.affixes = [{"id": "crit", "value": 20}, {"id": "bleed", "value": 4}]
 if weapon == "ipetam": result.artifact_kills = 0
 return result
static func gear_name(gear: Dictionary) -> String:
 return "%s·%s T%d" % [QUALITY[int(gear.quality)], WEAPONS[gear.weapon].name, gear.tier]
static func armor_value(gear: Dictionary) -> int:
 return 0 if gear.is_empty() else 12 + (int(gear.tier) - 1) * 3 + int(gear.bonus)
static func enemy(kind: String, level_value: int, elite: bool = false) -> Dictionary:
 level_value = clampi(level_value, 1, 20)
 var spec: Dictionary = MONSTERS[kind]
 return {"hp": roundi(spec.hp * (1 + 0.18 * (level_value - 1)) * (1.65 if elite else 1)), "damage": roundi(spec.damage * (1 + 0.10 * (level_value - 1)) * (1.2 if elite else 1)), "armor": int(spec.armor) + (level_value - 1) * 2 + (8 if kind == "bone" else 0), "level": level_value, "elite": elite}

static var icon_cache: Dictionary = {}
static func icon(weapon: String) -> AtlasTexture:
 if icon_cache.has(weapon): return icon_cache[weapon]
 var index: int = ICON_ORDER.find(weapon)
 var texture := AtlasTexture.new()
 texture.atlas = preload("res://assets/prajna.svg") if weapon == "prajna" else (preload("res://assets/weapons.png") if index < 5 else preload("res://assets/arsenal.svg"))
 texture.region = Rect2((0 if weapon == "prajna" else index if index < 5 else index - 5) * 24, 0, 24, 16)
 icon_cache[weapon] = texture
 return texture

static func artifact_level(gear: Dictionary) -> int:
 return mini(10, 1 + int(gear.get("artifact_kills", 0)) / 5)
static func lifesteal(gear: Dictionary) -> float:
 return 0.08 + artifact_level(gear) * 0.012
