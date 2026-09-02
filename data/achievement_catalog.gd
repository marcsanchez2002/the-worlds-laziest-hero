extends RefCounted


static func all() -> Array[Dictionary]:
	return [
		{
			"id": "first_blood",
			"name": "First Blood",
			"description": "Kill your first monster.",
			"type": "kills",
			"target": 1.0,
			"gold": 50.0,
			"lazy_power": 0.0,
		},
		{
			"id": "professional_lazy",
			"name": "Professional Lazy Person",
			"description": "Don't click ATTACK for 5 minutes.",
			"type": "no_manual",
			"target": 300.0,
			"gold": 0.0,
			"lazy_power": 0.05,
		},
		{
			"id": "too_lazy_to_fight",
			"name": "Too Lazy to Fight",
			"description": "Defeat a boss using only automation.",
			"type": "boss_no_manual",
			"target": 1.0,
			"gold": 250.0,
			"lazy_power": 0.0,
		},
		{
			"id": "nap_master",
			"name": "Nap Master",
			"description": "Spend 1 hour in the game.",
			"type": "play_time",
			"target": 3600.0,
			"gold": 0.0,
			"lazy_power": 0.1,
		},
		{
			"id": "worlds_laziest",
			"name": "The World's Laziest Hero",
			"description": "Reach the final world.",
			"type": "stage",
			"target": 201.0,
			"gold": 10000.0,
			"lazy_power": 0.25,
		},
	]


static func by_id(id: String) -> Dictionary:
	for item in all():
		if String(item["id"]) == id:
			return item
	return {}
