class_name YinIsland
extends RefCounted
const MINIONS = ["kappa", "chochin", "ippon_datara", "jorogumo", "sogenbi"]
const BOSSES = ["itsumade", "daitengu", "ryomen_sukuna"]
const ROWS = {"kappa": 0, "chochin": 1, "ippon_datara": 2, "jorogumo": 3, "sogenbi": 4, "itsumade": 5, "daitengu": 6, "ryomen_sukuna": 7}
const ARENAS = {"itsumade": Vector2(700, 352), "daitengu": Vector2(1568, 320), "ryomen_sukuna": Vector2(1824, 1184)}
const REGIONS = {"苇岸": Vector2(448, 960), "荒冢": Vector2(704, 352), "风山": Vector2(1568, 320), "双面社": Vector2(1824, 1184)}
static func texture(kind: String) -> Texture2D:
	return preload("res://assets/island_yokai.svg") if ROWS.has(kind) else preload("res://assets/enemies.png")
static func anatomy(kind: String) -> Array:
	if kind == "sogenbi": return []
	if kind == "chochin": return ["head"]
	return ["arm", "leg", "head"]
static func near_water(at: Vector2) -> bool:
	return absf(at.x - 992) < 108 or Rect2(288, 784, 384, 272).has_point(at)
static func water_tile(x: int, y: int) -> bool:
	return x < 2 or y < 2 or x >= 68 or y >= 48 or (x in [30, 31] and y not in [22, 23, 24, 25, 38, 39, 40]) or (x >= 11 and x <= 16 and y >= 26 and y <= 29)
static func available(state, kind: String) -> bool:
	if kind == "daitengu": return "itsumade" in state.island_journal.defeated
	if kind == "ryomen_sukuna": return "daitengu" in state.island_journal.defeated
	return true
static func populate(state) -> void:
	if not state.enemies.any(func(e): return e.zone == "island" and int(e.get("island_day", 0)) == state.day):
		for i in range(20):
			var kind: String = MINIONS[i % 5]
			var at: Vector2 = [
				Vector2(624, 928), Vector2(320, 672), Vector2(720, 608), Vector2(1424, 912), Vector2(1872, 704),
				Vector2(784, 1104), Vector2(400, 480), Vector2(1184, 592), Vector2(1568, 736), Vector2(2016, 912),
				Vector2(848, 784), Vector2(592, 464), Vector2(1344, 480), Vector2(1696, 944), Vector2(1984, 1328),
				Vector2(672, 1184), Vector2(400, 1120), Vector2(1408, 1200), Vector2(1616, 1376), Vector2(1888, 464)
			][i]
			var e: Dictionary = state.spawn_record(kind, "island", at, 3 + int((state.day - 1) / 5), i in [12, 18])
			e.island_day = state.day
			e.home_at = [at.x, at.y]
	for kind in BOSSES:
		if state.enemies.any(func(e): return e.kind == kind): continue
		var e: Dictionary = state.spawn_record(kind, "island", ARENAS[kind], 4 + BOSSES.find(kind), true)
		e.home_at = [ARENAS[kind].x, ARENAS[kind].y]
static func on_kill(state, enemy: Dictionary) -> void:
	if enemy.zone != "island": return
	if enemy.kind in MINIONS and enemy.kind not in state.island_journal.hunted: state.island_journal.hunted.append(enemy.kind)
	if enemy.kind in BOSSES and enemy.kind not in state.island_journal.defeated:
		state.island_journal.defeated.append(enemy.kind)
		state.add_log("岛国异闻：" + YinBalance.MONSTERS[enemy.kind].name + "已平息。")
static func validate(value: Variant) -> bool:
	if not value is Dictionary or not value.get("visited") is bool or not value.get("hunted") is Array or not value.get("defeated") is Array: return false
	for key in ["hunted", "defeated"]:
		var found: Array = []
		for kind in value[key]:
			if kind not in (MINIONS if key == "hunted" else BOSSES) or kind in found: return false
			found.append(kind)
	if "daitengu" in value.defeated and "itsumade" not in value.defeated: return false
	if "ryomen_sukuna" in value.defeated and "daitengu" not in value.defeated: return false
	return true
