class_name YinAbilities
extends RefCounted
const BOSSES = ["itsumade", "daitengu", "ryomen_sukuna", "boss", "well_boss", "opera_boss"]
const MONSTERS = {
 "kappa": {"active": "引水扑击", "passive": "头皿蓄水", "pattern": "river", "trait": "river"},
 "chochin": {"active": "长舌惊吓", "passive": "纸灯易燃", "pattern": "tongue", "trait": "paper"},
 "ippon_datara": {"active": "独足锻击", "passive": "山中独足", "pattern": "hammer", "trait": "hammer"},
 "jorogumo": {"active": "缠丝蛛网", "passive": "蛛女牵制", "pattern": "web", "trait": "web"},
 "sogenbi": {"active": "罪火飞散", "passive": "无躯妖火", "pattern": "wicked_flame", "trait": "flame"},
 "itsumade": {"active": "金羽毒鸣", "passive": "未葬者之怨", "pattern": "lament", "trait": "lament"},
 "daitengu": {"active": "羽扇山岚", "passive": "风障修验", "pattern": "gale", "trait": "gale"},
 "ryomen_sukuna": {"active": "双面剑弓", "passive": "四臂武威", "pattern": "dual", "trait": "dual"},
 "water": {"active": "寒水喷涌", "passive": "湿腐再生", "pattern": "cold", "trait": "regen"},
 "bone": {"active": "裂骨重击", "passive": "骨甲", "pattern": "slam", "trait": "armor"},
 "archer": {"active": "吐骨扇射", "passive": "穿骨", "pattern": "fan", "trait": "pierce"},
 "lantern": {"active": "灯火环爆", "passive": "返灯", "pattern": "ring", "trait": "siphon"},
 "gunner": {"active": "纸铳连射", "passive": "熟练填弹", "pattern": "burst", "trait": "reload"},
 "brute": {"active": "山魈冲锋", "passive": "狂性", "pattern": "charge", "trait": "rage"},
 "boss": {"active": "棺煞震荡", "passive": "棺甲", "pattern": "boss", "trait": "boss_armor"},
 "well_boss": {"active": "回潮水阵", "passive": "回潮", "pattern": "tide", "trait": "tide"},
 "opera_boss": {"active": "七幕飞针", "passive": "戏幕护盾", "pattern": "opera", "trait": "shield"}
}
const SKILLS = {
 "seal": {"name": "镇符", "level": 1, "parent": "", "cost": 12, "recharge": 12.0, "description": "消耗 12 体力与 1 充能，压制敌人；首领抗控制。"},
 "fire": {"name": "符火", "level": 2, "parent": "seal", "cost": 22, "recharge": 18.0, "description": "消耗 22 体力与 1 充能；火焚降低遗骸完整度。"},
 "breath": {"name": "调息", "level": 2, "parent": "seal", "cost": 0, "recharge": 0.0, "description": "被动：加快体力恢复，每阶 +0.25 / 秒。"},
 "command": {"name": "统御", "level": 4, "parent": "breath", "cost": 0, "recharge": 0.0, "description": "被动：每阶额外增加 1 个安置位，出战上限仍为 3 点。"}
}
const AFFIXES = {"crit": "暴击", "bleed": "重伤"}
static func meta(kind: String) -> Dictionary:
 return MONSTERS.get(kind, MONSTERS.lantern)
static func spirit_hp(kind: String, level: int) -> int:
 return (90 + (level - 1) * 10) if kind in BOSSES else (42 + (level - 1) * 7)
static func spirit_damage(spirit: Dictionary) -> int:
 return (7 if spirit.source_kind in BOSSES else 4) + int((spirit.level - 1) * 0.8) + int(spirit.affinity / 50)
static func deployment_cost(kind: String) -> int:
 return 2 if kind in BOSSES else 1
static func affix_text(gear: Dictionary) -> String:
 if gear.get("weapon") == "ipetam": return "神器 Lv%d · 击杀 %d · 吸血 %.1f%%" % [YinBalance.artifact_level(gear), gear.artifact_kills, YinBalance.lifesteal(gear) * 100]
 var result: Array[String] = []
 for affix in gear.get("affixes", []):
  result.append("%s %d%s" % [AFFIXES.get(affix.id, ""), affix.value, "%" if affix.id == "crit" else "秒"])
 var element: String = gear.get("enchantment", "")
 if element != "": result.append("附魔·" + YinBalance.ELEMENT_NAMES.get(element, element))
 return " / ".join(result) if not result.is_empty() else "无词条"
