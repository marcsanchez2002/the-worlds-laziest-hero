extends RefCounted


static func all() -> Array[Dictionary]:
	return [
		{
			"id": "wooden",
			"name": "Wooden Sword",
			"unlock_stage": 1,
			"damage_per_level": 1.0,
			"special": "",
			"upgrade_base_cost": 25.0,
			"description": "A stick that almost looks like a sword. Basic damage.",
		},
		{
			"id": "lazy",
			"name": "Lazy Sword",
			"unlock_stage": 8,
			"damage_per_level": 2.0,
			"special": "auto",
			"upgrade_base_cost": 80.0,
			"description": "Attacks automatically. Why swing it yourself?",
		},
		{
			"id": "telekinetic",
			"name": "Telekinetic Sword",
			"unlock_stage": 20,
			"damage_per_level": 3.0,
			"special": "telekinetic",
			"upgrade_base_cost": 220.0,
			"description": "The sword attacks while the hero sleeps.",
		},
		{
			"id": "minimal",
			"name": "Sword of Minimal Effort",
			"unlock_stage": 35,
			"damage_per_level": 9.0,
			"special": "slow_heavy",
			"upgrade_base_cost": 450.0,
			"description": "Huge hits. Painfully slow. Perfect.",
		},
		{
			"id": "bed_sword",
			"name": "Legendary Bed Sword",
			"unlock_stage": 80,
			"damage_per_level": 18.0,
			"special": "bed",
			"upgrade_base_cost": 1800.0,
			"description": "A gigantic sword that floats above the bed.",
		},
	]


static func by_id(id: String) -> Dictionary:
	for weapon in all():
		if String(weapon["id"]) == id:
			return weapon
	return all()[0]
