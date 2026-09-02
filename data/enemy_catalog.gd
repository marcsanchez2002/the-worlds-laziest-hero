extends RefCounted

const BALANCE := preload("res://data/balance.tres")
const WorldCatalog := preload("res://data/world_catalog.gd")


static func for_stage(stage: int) -> Dictionary:
	var safe_stage: int = maxi(1, stage)
	var world: Dictionary = WorldCatalog.for_stage(safe_stage)
	var is_world_boss: bool = safe_stage == int(world["stage_end"])
	var is_boss: bool = is_world_boss or (safe_stage % 10 == 0)
	var template: Dictionary
	if is_world_boss:
		template = _template(String(world["boss_id"]))
	else:
		var pool: Array = world["enemy_ids"]
		var offset: int = safe_stage - int(world["stage_start"])
		var template_id: String = String(pool[offset % pool.size()])
		template = _template(template_id)
	var hp: float = float(template["base_hp"]) * pow(BALANCE.enemy_hp_scaling, float(safe_stage - 1))
	var gold: float = float(template["base_gold"]) * pow(BALANCE.gold_scaling, float(safe_stage - 1))
	if is_world_boss:
		hp *= BALANCE.world_boss_hp_mult
		gold *= BALANCE.world_boss_gold_mult
	elif is_boss:
		hp *= BALANCE.boss_hp_mult
		gold *= BALANCE.boss_gold_mult
	if String(template.get("mechanic", "")) == "tank":
		hp *= 1.8
	var color: Color = template["color"]
	if is_boss:
		color = color.lightened(0.18)
	var display_name: String = String(template["name"])
	if is_world_boss:
		display_name = String(template.get("boss_name", template["name"]))
	elif is_boss:
		display_name = String(template.get("boss_name", "THE BIG %s" % String(template["name"]).to_upper()))
	return {
		"id": String(template["id"]),
		"display_name": display_name,
		"max_hp": maxf(1.0, roundf(hp)),
		"gold_reward": gold,
		"color": color,
		"is_boss": is_boss,
		"is_world_boss": is_world_boss,
		"mechanic": String(template.get("mechanic", "")),
		"move_speed": float(template.get("move_speed", 50.0)),
		"attack_range": float(template.get("attack_range", 80.0)),
		"attack_damage": maxf(1.0, roundf(float(template.get("attack_damage", 1.0)))),
		"attack_cooldown": float(template.get("attack_cooldown", 2.0)),
		"world_id": int(world["id"]),
		"world_name": String(world["name"]),
		"world_gold_mult": float(world["gold_mult"]),
		"texture": String(template.get("texture", "")),
	}


static func event_enemy(event_id: String, stage: int) -> Dictionary:
	var base := for_stage(stage)
	var template := _event_template(event_id)
	base["id"] = String(template["id"])
	base["display_name"] = String(template["name"])
	base["max_hp"] = maxf(1.0, roundf(float(template["hp_mult"]) * float(base["max_hp"])))
	base["gold_reward"] = float(template["gold_mult"]) * float(base["gold_reward"])
	base["color"] = template["color"]
	base["is_boss"] = bool(template.get("is_boss", false))
	base["is_world_boss"] = false
	base["mechanic"] = String(template.get("mechanic", ""))
	base["event_id"] = event_id
	base["texture"] = String(template.get("texture", ""))
	return base


static func _event_template(event_id: String) -> Dictionary:
	match event_id:
		"angry_villager":
			return {
				"id": "angry_villager",
				"name": "Angry Villager",
				"hp_mult": 1.2,
				"gold_mult": 2.0,
				"color": Color(0.82, 0.42, 0.28),
				"is_boss": true,
				"mechanic": "retaliate",
			}
		_:
			return {
				"id": "sleeping_goblin",
				"name": "Sleeping Goblin",
				"hp_mult": 0.7,
				"gold_mult": 6.0,
				"color": Color(0.55, 0.78, 0.42),
				"is_boss": true,
				"mechanic": "sleep_resist",
			}


static func _template(id: String) -> Dictionary:
	match id:
		"goblin":
			return _make("goblin", "Goblin", "THE BIG GOBLIN", 50.0, 15.0, Color(0.45, 0.7, 0.28), "", 80.0, 80.0, 2.0, 1.5)
		"orc":
			return _make("orc", "Orc", "THE BIG ORC", 120.0, 40.0, Color(0.28, 0.52, 0.22), "", 35.0, 90.0, 5.0, 2.5)
		"skeleton":
			return _make("skeleton", "Skeleton", "THE BONE LORD", 90.0, 28.0, Color(0.86, 0.84, 0.78), "", 70.0, 80.0, 3.0, 1.8)
		"wolf":
			return _make("wolf", "Wolf", "THE ALPHA WOLF", 70.0, 22.0, Color(0.45, 0.42, 0.4), "", 120.0, 70.0, 3.0, 1.2)
		"dark_knight":
			return _make("dark_knight", "Dark Knight", "THE DARK CHAMPION", 200.0, 55.0, Color(0.22, 0.22, 0.32), "tank", 40.0, 90.0, 6.0, 2.2)
		"vampire":
			return _make("vampire", "Vampire", "THE NIGHT COUNT", 180.0, 60.0, Color(0.55, 0.12, 0.2), "retaliate", 75.0, 85.0, 4.0, 1.6)
		"golem":
			return _make("golem", "Golem", "THE STONE COLOSSUS", 260.0, 70.0, Color(0.55, 0.5, 0.42), "tank", 25.0, 100.0, 6.0, 3.0)
		"dragon":
			return _make("dragon", "Dragon", "THE LAZY WYRM", 320.0, 90.0, Color(0.72, 0.22, 0.18), "", 45.0, 110.0, 7.0, 2.8)
		"demon":
			return _make("demon", "Demon", "THE OVERACHIEVER", 280.0, 85.0, Color(0.62, 0.1, 0.18), "retaliate", 60.0, 90.0, 5.0, 1.8)
		"angry_king":
			return _make("angry_king", "The Angry King", "The Angry King", 160.0, 80.0, Color(0.78, 0.62, 0.2), "retaliate", 40.0, 90.0, 6.0, 2.0)
		"nightmare_wolf":
			return _make("nightmare_wolf", "The Nightmare Wolf", "The Nightmare Wolf", 220.0, 95.0, Color(0.28, 0.22, 0.35), "tank", 100.0, 80.0, 5.0, 1.4)
		"giant_goblin":
			return _make("giant_goblin", "The Giant Goblin", "The Giant Goblin", 400.0, 120.0, Color(0.32, 0.62, 0.22), "tank", 30.0, 100.0, 8.0, 2.6)
		"sleeping_dragon":
			return _make("sleeping_dragon", "The Sleeping Dragon", "The Sleeping Dragon", 350.0, 140.0, Color(0.35, 0.28, 0.55), "sleep_resist", 35.0, 110.0, 7.0, 3.0)
		"demon_productivity":
			return _make("demon_productivity", "The Demon of Productivity", "The Demon of Productivity", 480.0, 200.0, Color(0.85, 0.35, 0.12), "retaliate_resist", 55.0, 95.0, 8.0, 2.0)
		_:
			return _make("slime", "Slime", "THE BIG SLIME", 20.0, 5.0, Color(0.35, 0.85, 0.4), "", 50.0, 80.0, 1.0, 2.0, "res://assets/enemies/slime.png")


static func _make(
	id: String,
	name: String,
	boss_name: String,
	hp: float,
	gold: float,
	color: Color,
	mechanic: String,
	move_speed: float = 50.0,
	attack_range: float = 80.0,
	attack_damage: float = 1.0,
	attack_cooldown: float = 2.0,
	texture: String = ""
) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"boss_name": boss_name,
		"base_hp": hp,
		"base_gold": gold,
		"color": color,
		"mechanic": mechanic,
		"move_speed": move_speed,
		"attack_range": attack_range,
		"attack_damage": attack_damage,
		"attack_cooldown": attack_cooldown,
		"texture": texture,
	}
