class_name YinTemple
extends RefCounted
const MINIONS = ["hungry_ghost", "wraith", "rakshasa", "kumbhanda"]
const BOSSES = ["asura", "yaksha"]
const ROWS = {"hungry_ghost": 0, "wraith": 1, "rakshasa": 2, "kumbhanda": 3, "asura": 4, "yaksha": 5}
const ARENAS = {"asura": Vector2(704, 512), "yaksha": Vector2(1248, 288)}
const REGIONS = {"施食庭": Vector2(448, 992), "塔林": Vector2(416, 640), "梦障院": Vector2(1184, 928), "修罗道场": Vector2(704, 512), "护法殿": Vector2(1248, 288)}
const ENTRY = Vector2(224, 1120)
const EXIT = Vector2(176, 1152)
const VILLAGE_GATE = Vector2(1120, 160)
static func initial() -> Dictionary:
	return {"visited": false, "hunted": [], "defeated": []}
static func available(s, kind: String) -> bool:
	return kind != "yaksha" or "asura" in s.temple_journal.defeated
static func populate(s) -> void:
	if not s.enemies.any(func(e): return e.zone == "temple" and int(e.get("temple_day", 0)) == s.day):
		for i in range(16):
			var kind: String = MINIONS[i % 4]
			var at: Vector2 = [Vector2(448, 1024), Vector2(384, 672), Vector2(864, 768), Vector2(1184, 928), Vector2(608, 896), Vector2(480, 576), Vector2(960, 544), Vector2(1312, 992), Vector2(320, 896), Vector2(288, 512), Vector2(1088, 704), Vector2(1152, 1088), Vector2(768, 992), Vector2(384, 416), Vector2(1408, 480), Vector2(1280, 800)][i]
			var e: Dictionary = s.spawn_record(kind, "temple", at, 3 + int((s.day - 1) / 5), i in [10, 14])
			e.temple_day = s.day
			e.home_at = [at.x, at.y]
	for kind in BOSSES:
		if s.enemies.any(func(e): return e.kind == kind): continue
		var e: Dictionary = s.spawn_record(kind, "temple", ARENAS[kind], 5 + BOSSES.find(kind), true)
		e.home_at = [ARENAS[kind].x, ARENAS[kind].y]
static func on_kill(s, e: Dictionary) -> void:
	if e.zone != "temple" or e.has("war_id"): return
	if e.kind in MINIONS and e.kind not in s.temple_journal.hunted: s.temple_journal.hunted.append(e.kind)
	if e.kind in BOSSES and e.kind not in s.temple_journal.defeated:
		s.temple_journal.defeated.append(e.kind)
		s.add_log("佛寺异闻：" + YinBalance.MONSTERS[e.kind].name + "已平息。")
static func validate(value: Variant) -> bool:
	if not value is Dictionary or not value.get("visited") is bool: return false
	for key in ["hunted", "defeated"]:
		if not value.get(key) is Array: return false
		var found: Array = []
		for kind in value[key]:
			if kind not in (MINIONS if key == "hunted" else BOSSES) or kind in found: return false
			found.append(kind)
	return "yaksha" not in value.defeated or "asura" in value.defeated
