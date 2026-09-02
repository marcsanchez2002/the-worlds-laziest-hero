extends RefCounted


static func all() -> Array[Dictionary]:
	return [
		{
			"id": "kill_10",
			"name": "Kill 10 Monsters",
			"description": "Defeat 10 enemies. Or have someone else do it.",
			"type": "kills",
			"target": 10.0,
			"gold": 100.0,
			"lazy_power": 0.0,
			"repeatable": true,
		},
		{
			"id": "reach_25",
			"name": "Reach Stage 25",
			"description": "Get to stage 25 without standing up.",
			"type": "stage",
			"target": 25.0,
			"gold": 1000.0,
			"lazy_power": 0.0,
			"repeatable": false,
		},
		{
			"id": "buy_10",
			"name": "Buy 10 Upgrades",
			"description": "Purchase 10 upgrades. Shopping counts as work.",
			"type": "upgrades",
			"target": 10.0,
			"gold": 0.0,
			"lazy_power": 0.05,
			"repeatable": false,
		},
		{
			"id": "boss_auto",
			"name": "Hands-Free Boss",
			"description": "Defeat a boss without a single manual attack.",
			"type": "boss_no_manual",
			"target": 1.0,
			"gold": 500.0,
			"lazy_power": 0.05,
			"repeatable": false,
		},
		{
			"id": "reach_world_2",
			"name": "Leave the Village",
			"description": "Reach World 2: Dark Forest.",
			"type": "stage",
			"target": 51.0,
			"gold": 2500.0,
			"lazy_power": 0.05,
			"repeatable": false,
		},
	]


static func by_id(id: String) -> Dictionary:
	for quest in all():
		if String(quest["id"]) == id:
			return quest
	return {}
