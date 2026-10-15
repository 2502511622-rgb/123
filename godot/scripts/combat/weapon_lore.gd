class_name YinWeaponLore
extends RefCounted
const TEXT = {
"sword":"桃木辟邪剑。近身扇形挥斩，可边走边攻。",
"silver_sword":"银刃长剑。范围挥斩，适合压制贴身敌群。",
"whip":"长鞭。远于剑的扇形打击，注意挥出时机。",
"pistol":"轻便手枪。指向射击，弹匣耗尽需装填。",
"smg":"冲锋枪。近中距离连续压制，使用轻型弹药。",
"rifle":"长管步枪。远距离精确射击，注意弹药。",
"revolver":"六发左轮。单发威力高，装填时可闪避脱离。",
"gatling":"加特林。按住攻击预热后连射，消耗步枪弹药。",
"spellbook":"魔法书。发射法术弹，消耗气力并携带自带附魔。",
"curse_doll":"咒术娃娃。诅咒附近可见敌人并持续造成流血。",
"ipetam":"伊佩塔姆。吸血妖刀，随击杀成长，带独立刀光。",
"prajna":"文殊般若剑。随修为成长，同时触发三种元素附魔。",
"armor":"护身衣甲。装备后降低受到的物理伤害。"
}
static func describe(kind: String) -> String:
	return TEXT.get(kind,"缝合世界的旅装。获取时即具有自身词条。")
