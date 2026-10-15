extends SceneTree
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
func _initialize() -> void:
	var state := FarmState.new()
	var pistol: Dictionary = state.equipment[1]
	var rifle: Dictionary = state.grant_gear("rifle")
	state.equip(rifle.id)
	check(state.weapon_slots.primary == rifle.id and state.weapon_slots.secondary == pistol.id, "equipping populates distinct primary and secondary slots")
	state.cycle_weapon(1)
	check(state.current_gear().weapon == "pistol", "wheel cycle moves primary to secondary")
	state.cycle_weapon(1)
	check(state.current_gear().weapon == "sword", "wheel cycle moves secondary to melee")
	state.cycle_weapon(-1)
	check(state.current_gear().weapon == "pistol", "reverse wheel selects previous occupied slot")
	pistol.magazine = 5
	state.cycle_weapon(1)
	state.cycle_weapon(-1)
	check(pistol.magazine == 5, "cycling slots preserves each magazine")
	check("不可拆解" in state.salvage(rifle.id), "loadout gear cannot be accidentally salvaged")
	check(state.skill_points() == 0 and "技能点" in state.learn_skill("fire"), "new character cannot learn free skills without a point")
	state.cultivation = 80
	check(state.skill_points() == 1 and "已学习" in state.learn_skill("fire"), "level two unlocks fire through skill points")
	var stock: int = state.talismans
	check(state.spend_skill("fire") and state.energy == 78 and state.skill_charges.fire == 1 and state.talismans == stock, "fire spends stamina and one charge, no talismans")
	state.update_combat(17.0)
	check(state.skill_charges.fire == 1, "charge cannot return before recovery interval")
	state.update_combat(1.0)
	check(state.skill_charges.fire == 2, "charge automatically returns after eighteen seconds")
	state.energy = 1
	var charge: int = state.skill_charges.seal
	check(not state.spend_skill("seal") and state.skill_charges.seal == charge, "failed low-stamina cast preserves charge")
	state.energy = 100
	state.spend_skill("seal")
	state.spend_skill("seal")
	check(not state.spend_skill("seal"), "empty skill charges stop spamming")
	state.update_combat(100)
	check(state.skill_charges.seal == 2 and state.skill_timers.seal == 0 and state.energy <= 100, "charge and stamina recovery are capped")
	state.cultivation = 240
	check("前置" in state.learn_skill("command"), "command skill respects breath prerequisite")
	state.learn_skill("breath")
	state.learn_skill("command")
	check(state.capacity() == 4 and state.deployment_used() == 0, "command expands roster but not deployed power")
	for kind in YinBalance.MONSTERS:
		check(YinAbilities.meta(kind).active != "" and YinAbilities.meta(kind).passive != "", "each monster and boss has active and passive: " + kind)
	check(YinBalance.enemy("bone", 1).armor >= 8, "bone armor passive changes real defense")
	check(YinBalance.MONSTERS.boss.hp >= 500 and YinBalance.MONSTERS.well_boss.hp >= 400, "boss baseline health increased materially")
	var boss: Dictionary = state.spawn_record("boss", "farm", Vector2(400, 350), 4, true)
	state.kill_enemy(boss.id, Vector2(400, 350))
	var remains_id: int = state.remains[-1].id
	state.oil = 0
	check("完成" in state.process_remains(remains_id, "refine") and state.oil == 0, "boss refinement works without oil")
	state.oil = 20
	state.process_remains(remains_id, "refine")
	var follower: Dictionary = state.spirits[0]
	check(follower.source_kind == "boss" and follower.level == 4 and follower.hp == follower.max_hp and state.deployment_used() == 2, "boss refinement inherits source skills and bounded stats")
	check(YinAbilities.spirit_damage(follower) < 12 and follower.max_hp < boss.max_hp / 2, "refined boss does not keep enemy boss power")
	state.spirits.append(state.make_spirit("water", 10))
	state.spirits.append(state.make_spirit("gunner", 10))
	check(state.deployment_used() == 3 and not state.spirits[2].active, "excess recruited follower waits at home")
	check("上限" in state.deploy_spirit(state.spirits[2].id, true), "deployment cap rejects a fourth power point")
	state.bones = 4
	var old_hp: int = follower.max_hp
	check("完成" in state.train_spirit(follower.id) and follower.level == 5 and follower.max_hp > old_hp and follower.source_kind == "boss", "training levels follower while retaining inherited abilities")
	state.gain_spirit_xp(follower, 200)
	check(follower.level == 6, "combat experience independently levels follower")
	follower.hp = 0
	follower.active = false
	check("倒下" in state.deploy_spirit(follower.id, true), "fallen follower cannot be deployed")
	state.heal_spirit(follower.id)
	check(follower.hp == follower.max_hp, "healing recovers fallen follower")
	var dismissed_id: int = state.spirits[2].id
	check("解除" in state.dismiss_spirit(dismissed_id) and not state.spirits.any(func(s): return s.id == dismissed_id), "dismiss permanently removes follower contract")
	var loot := FarmState.new()
	var equipment_count: int = 0
	var gun_count: int = 0
	var materials: int = 0
	var valid_loot: bool = true
	for id in range(1, 1001):
		loot.gear_drops.clear()
		loot.drops.clear()
		loot.reward_enemy({"id": id, "kind": "bone", "level": 1, "elite": false, "zone": "graveyard"}, Vector2(400, 350))
		check_loot_ammo(loot)
		materials += loot.drops.filter(func(drop): return drop.item not in ["light_ammo", "rifle_ammo"]).size()
		for drop in loot.gear_drops:
			equipment_count += 1
			if drop.gear.weapon in ["pistol", "smg", "rifle"]: gun_count += 1
			valid_loot = valid_loot and FarmState.valid_gear(drop.gear)
	check(equipment_count > 70 and equipment_count < 170, "ordinary equipment drop frequency falls to around twelve percent")
	check(gun_count > 0 and gun_count < equipment_count * 0.25, "guns are substantially rarer than melee and armor")
	check(materials > 600 and materials < 850 and valid_loot, "materials remain common and every rolled affix is valid")
	var elite_rolls: int = 0
	var elite_magic: bool = true
	for id in range(1, 301):
		loot.gear_drops.clear()
		loot.reward_enemy({"id": id, "kind": "brute", "level": 3, "elite": true, "zone": "forest"}, Vector2(400, 350))
		for drop in loot.gear_drops:
			elite_rolls += 1
			elite_magic = elite_magic and drop.gear.quality >= 1
	check(elite_rolls > 60 and elite_rolls < 150 and elite_magic, "elite equipment is probabilistic and preserves quality floor")
	var weapon: Dictionary = state.grant_gear("rifle", 3, 2)
	check(weapon.affixes.size() == 2, "rare weapons arrive with two innate affixes")
	check(weapon.affixes[0].id != weapon.affixes[1].id, "innate affixes never duplicate")
	check(FarmState.valid_gear(weapon), "innate weapon satisfies save schema")
	check(not state.has_method("inscribe_gear"), "inscription economy has been removed")
	var village := FarmState.new()
	village.next_day()
	village.next_day()
	check(village.day == 3 and village.letters.size() == 1 and village.raid_status == "warned", "third morning sends real rescue letter")
	village.minutes = 1080
	check(village.update_raid() and village.enemies.filter(func(e): return e.zone == "village").size() == 4, "evening spawns four attackers in new village")
	check(not village.update_raid() and village.enemies.size() == 4, "raid cannot spawn twice")
	for enemy in village.enemies: village.kill_enemy(enemy.id, Vector2(1000, 500))
	var money_before: int = village.money
	village.update_raid()
	check(village.raid_status == "success" and village.money == money_before + 30 and village.letters[0].status == "success", "killing actual raid records resolves rescue and pays once")
	village.update_raid()
	check(village.money == money_before + 30, "rescue reward cannot be collected repeatedly")
	village.next_day()
	village.next_day()
	village.next_day()
	check(village.day == 6 and village.letters.size() == 2, "new rescue arrives every three days")
	village.minutes = 1080
	village.update_raid()
	village.next_day()
	check(village.raid_status == "failed" and village.village_integrity == 80 and village.villagers[0].hp < 100, "ignored raid injures villagers and damages settlement")
	var restored := FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(state.snapshot()))) and restored.spirits == state.spirits, "new skills, weapon slots and inherited followers round-trip through JSON")
	check(restored.restore(JSON.parse_string(JSON.stringify(village.snapshot()))) and restored.letters.size() == 2, "village letters and raid outcomes round-trip")
	var old: Dictionary = FarmState.new().snapshot()
	old.version = 5
	for key in ["weapon_slots", "active_slot", "skill_ranks", "skill_charges", "skill_timers", "villagers", "letters", "raid_day", "raid_status", "village_integrity"]: old.erase(key)
	for gear in old.equipment: gear.erase("affixes")
	check(restored.restore(old) and restored.weapon_slots.secondary == 2 and restored.skill_ranks.seal == 1, "schema five migrates to skill and loadout model")
	var bad: Dictionary = state.snapshot()
	bad.skill_ranks.command = 3
	check(not restored.restore(bad), "forged skill points rejected atomically")
	bad = state.snapshot()
	bad.equipment[0].affixes = [{"id": "crit", "value": 100}]
	check(not restored.restore(bad), "forged critical chance rejected")
	bad = state.snapshot()
	bad.skill_timers.fire = NAN
	check(not restored.restore(bad), "nonfinite charge timer rejected")
	print("Campaign rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func check_loot_ammo(state: FarmState) -> void:
	# Aggregate, rather than creating one redundant assertion per random sample.
	if not state.drops.any(func(drop): return drop.item in ["light_ammo", "rifle_ammo"] and drop.count >= 6):
		push_error("Ammo supply absent from drop sample")
		failures += 1
