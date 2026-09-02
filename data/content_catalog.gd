extends RefCounted


static func shop() -> Array[Dictionary]:
	return [
		{"id": "perm_damage", "name": "+5% Permanent Damage", "description": "Keeps working after every nap.", "stat": "damage", "value": 0.05, "base_cost": 1},
		{"id": "perm_gold", "name": "+5% Permanent Gold", "description": "The king keeps paying you to stay in bed.", "stat": "gold", "value": 0.05, "base_cost": 1},
		{"id": "perm_crit", "name": "+1% Critical Chance", "description": "Critical hits, minimum effort.", "stat": "crit", "value": 0.01, "base_cost": 2},
	]


static func events() -> Array[Dictionary]:
	return [
		{"id": "sleeping_goblin", "name": "Sleeping Goblin", "kind": "enemy", "description": "A goblin is asleep. Defeat it for +500% gold."},
		{"id": "treasure_chest", "name": "Treasure Chest", "kind": "gold", "description": "A chest appeared. Open it without standing up.", "gold_mult": 8.0},
		{"id": "angry_villager", "name": "Angry Villager", "kind": "enemy", "description": "A villager is furious that you will not get up."},
		{"id": "royal_messenger", "name": "Royal Messenger", "kind": "gold", "description": "The king pays you to do nothing.", "gold_mult": 12.0},
	]


static func by_event(id: String) -> Dictionary:
	for event in events():
		if String(event["id"]) == id:
			return event
	return {}
