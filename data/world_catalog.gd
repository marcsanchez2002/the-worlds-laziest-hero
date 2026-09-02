extends RefCounted


static func all() -> Array[Dictionary]:
	return [
		{
			"id": 1,
			"name": "The Starting Village",
			"stage_start": 1,
			"stage_end": 50,
			"gold_mult": 1.0,
			"enemy_ids": ["slime", "goblin", "orc"],
			"boss_id": "angry_king",
		},
		{
			"id": 2,
			"name": "Dark Forest",
			"stage_start": 51,
			"stage_end": 100,
			"gold_mult": 1.2,
			"enemy_ids": ["wolf", "skeleton", "goblin"],
			"boss_id": "nightmare_wolf",
		},
		{
			"id": 3,
			"name": "Goblin Kingdom",
			"stage_start": 101,
			"stage_end": 150,
			"gold_mult": 1.45,
			"enemy_ids": ["goblin", "orc", "dark_knight"],
			"boss_id": "giant_goblin",
		},
		{
			"id": 4,
			"name": "Dragon Mountains",
			"stage_start": 151,
			"stage_end": 200,
			"gold_mult": 1.75,
			"enemy_ids": ["golem", "vampire", "dragon"],
			"boss_id": "sleeping_dragon",
		},
		{
			"id": 5,
			"name": "The Underworld",
			"stage_start": 201,
			"stage_end": 250,
			"gold_mult": 2.2,
			"enemy_ids": ["demon", "dark_knight", "vampire", "dragon"],
			"boss_id": "demon_productivity",
		},
	]


static func for_stage(stage: int) -> Dictionary:
	var safe := maxi(1, stage)
	for world in all():
		if safe >= int(world["stage_start"]) and safe <= int(world["stage_end"]):
			return world
	return all()[all().size() - 1]


static func is_unlocked(stage_reached: int, world: Dictionary) -> bool:
	return stage_reached >= int(world["stage_start"])
