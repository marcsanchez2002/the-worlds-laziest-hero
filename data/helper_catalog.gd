extends RefCounted


static func all() -> Array[Dictionary]:
	return [
		{
			"id": "squire",
			"name": "Lazy Squire",
			"role": "dps",
			"base_value": 5.0,
			"base_cost": 500.0,
			"description": "Stands nearby and occasionally pokes the enemy.",
		},
		{
			"id": "archer",
			"name": "Lazy Archer",
			"role": "ranged_dps",
			"base_value": 6.0,
			"base_cost": 900.0,
			"description": "Shoots from a hammock. Accuracy optional.",
		},
		{
			"id": "mage",
			"name": "Lazy Mage",
			"role": "magic_dps",
			"base_value": 8.0,
			"base_cost": 1400.0,
			"description": "Casts spells without sitting up. Magic damage.",
		},
		{
			"id": "healer",
			"name": "Lazy Healer",
			"role": "heal",
			"base_value": 1.5,
			"base_cost": 800.0,
			"description": "Restores Comfort and a tiny damage bonus.",
		},
		{
			"id": "blacksmith",
			"name": "Lazy Blacksmith",
			"role": "weapon",
			"base_value": 0.04,
			"base_cost": 1600.0,
			"description": "Improves equipped weapon damage while napping.",
		},
		{
			"id": "butler",
			"name": "Lazy Butler",
			"role": "gold",
			"base_value": 0.05,
			"base_cost": 1200.0,
			"description": "Collects gold so the hero does not have to get up.",
		},
	]


static func by_id(id: String) -> Dictionary:
	for helper in all():
		if String(helper["id"]) == id:
			return helper
	return {}
