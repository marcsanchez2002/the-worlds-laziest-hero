extends RefCounted


static func all() -> Array[Dictionary]:
	return [
		{
			"id": "lazy_slap",
			"name": "Lazy Slap",
			"description": "A devastating slap delivered without sitting up.",
			"cooldown": 30.0,
			"unlock_stage": 1,
			"key": KEY_Q,
		},
		{
			"id": "nap_time",
			"name": "Nap Time",
			"description": "10 seconds of serious napping. +100% DPS.",
			"cooldown": 45.0,
			"unlock_stage": 5,
			"key": KEY_W,
		},
		{
			"id": "do_nothing",
			"name": "Do Nothing",
			"description": "Do absolutely nothing for 5 seconds. Then +500% damage.",
			"cooldown": 40.0,
			"unlock_stage": 10,
			"key": KEY_E,
		},
		{
			"id": "bedquake",
			"name": "Bedquake",
			"description": "The bed trembles and smashes the enemy.",
			"cooldown": 35.0,
			"unlock_stage": 20,
			"key": KEY_R,
		},
		{
			"id": "procrastination",
			"name": "Procrastination",
			"description": "Delay the enemy. Double the reward when they finally fall.",
			"cooldown": 50.0,
			"unlock_stage": 30,
			"key": KEY_T,
		},
	]


static func by_id(id: String) -> Dictionary:
	for skill in all():
		if String(skill["id"]) == id:
			return skill
	return {}
