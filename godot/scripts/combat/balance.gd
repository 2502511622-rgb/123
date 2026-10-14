class_name YinBalance
extends RefCounted
const WEAPONS = {
 "sword": {"name": "桃木剑", "damage": 15, "interval": 0.32, "magazine": 0, "reload": 0.0, "ammo": "", "speed": 0, "spread": 0.0, "range": 49},
 "pistol": {"name": "手枪", "damage": 19, "interval": 0.28, "magazine": 8, "reload": 1.0, "ammo": "light_ammo", "speed": 700, "spread": 0.018, "range": 650},
 "smg": {"name": "冲锋枪", "damage": 9, "interval": 0.09, "magazine": 24, "reload": 1.4, "ammo": "light_ammo", "speed": 750, "spread": 0.09, "range": 560},
 "rifle": {"name": "步枪", "damage": 31, "interval": 0.2, "magazine": 12, "reload": 1.6, "ammo": "rifle_ammo", "speed": 1000, "spread": 0.008, "range": 1000},
 "armor": {"name": "镇煞护甲", "damage": 0, "interval": 0.0, "magazine": 0, "reload": 0.0, "ammo": "", "speed": 0, "spread": 0.0, "range": 0}
}
const QUALITY = ["凡品", "灵纹", "珍品", "异宝"]
const COLORS = [Color("c5c8b5"), Color("84bdda"), Color("e5c477"), Color("e7a46e")]
const MONSTERS = {
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
 var raw: float = base * (1 + 0.07 * (tier - 1) + 0.02 * (actor_level - 1)) * (1 + bonus / 100.0)
 return maxi(1, roundi(raw * 100.0 / (100 + maxi(0, armor))))
static func make_gear(id: int, weapon: String, tier: int = 1, quality: int = 0) -> Dictionary:
 return {"id": id, "weapon": weapon, "tier": tier, "quality": quality, "bonus": quality * 8, "magazine": 0, "affixes": []}
static func gear_name(gear: Dictionary) -> String:
 return "%s·%s T%d" % [QUALITY[int(gear.quality)], WEAPONS[gear.weapon].name, gear.tier]
static func armor_value(gear: Dictionary) -> int:
 return 0 if gear.is_empty() else 12 + (int(gear.tier) - 1) * 3 + int(gear.bonus)
static func enemy(kind: String, level_value: int, elite: bool = false) -> Dictionary:
 level_value = clampi(level_value, 1, 20)
 var spec: Dictionary = MONSTERS[kind]
 return {"hp": roundi(spec.hp * (1 + 0.18 * (level_value - 1)) * (1.65 if elite else 1)), "damage": roundi(spec.damage * (1 + 0.10 * (level_value - 1)) * (1.2 if elite else 1)), "armor": int(spec.armor) + (level_value - 1) * 2 + (8 if kind == "bone" else 0), "level": level_value, "elite": elite}
