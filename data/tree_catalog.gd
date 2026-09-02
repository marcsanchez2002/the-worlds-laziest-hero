extends RefCounted


static func all() -> Array[Dictionary]:
	return [
		{"id": "sharper_slaps", "branch": "COMBAT", "name": "Sharper Slaps", "description": "+10% damage.", "cost": 1, "requires": [], "damage": 0.1, "gold": 0.0, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0},
		{"id": "critical_naps", "branch": "COMBAT", "name": "Critical Naps", "description": "+2% critical chance.", "cost": 2, "requires": ["sharper_slaps"], "damage": 0.0, "gold": 0.0, "offline": 0.0, "crit": 0.02, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0},
		{"id": "heavy_pillow", "branch": "COMBAT", "name": "Heavy Pillow", "description": "+25% critical damage.", "cost": 3, "requires": ["critical_naps"], "damage": 0.0, "gold": 0.0, "offline": 0.0, "crit_damage": 0.25, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0},
		{"id": "combo_cushion", "branch": "COMBAT", "name": "Combo Cushion", "description": "Combo lasts 1s longer.", "cost": 3, "requires": ["sharper_slaps"], "damage": 0.0, "gold": 0.0, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 1.0},
		{"id": "spare_change", "branch": "ECONOMY", "name": "Spare Change", "description": "+10% gold.", "cost": 1, "requires": [], "damage": 0.0, "gold": 0.1, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0},
		{"id": "royal_allowance", "branch": "ECONOMY", "name": "Royal Allowance", "description": "+25% gold.", "cost": 3, "requires": ["spare_change"], "damage": 0.0, "gold": 0.25, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0},
		{"id": "sleepy_taxes", "branch": "ECONOMY", "name": "Sleepy Taxes", "description": "+15% gold.", "cost": 2, "requires": ["spare_change"], "damage": 0.0, "gold": 0.15, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0},
		{"id": "golden_drool", "branch": "ECONOMY", "name": "Golden Drool", "description": "+50% gold.", "cost": 5, "requires": ["royal_allowance"], "damage": 0.0, "gold": 0.5, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0},
		{"id": "snooze_button", "branch": "AUTOMATION", "name": "Snooze Button", "description": "Auto-attack 15% faster.", "cost": 1, "requires": [], "damage": 0.0, "gold": 0.0, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.15, "helper": 0.0, "nap": 0.0, "combo": 0.0},
		{"id": "extra_hands", "branch": "AUTOMATION", "name": "Extra Hands", "description": "+15% helper DPS.", "cost": 2, "requires": ["snooze_button"], "damage": 0.0, "gold": 0.0, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.15, "nap": 0.0, "combo": 0.0},
		{"id": "night_shift", "branch": "AUTOMATION", "name": "Night Shift", "description": "+15% helper DPS.", "cost": 3, "requires": ["extra_hands"], "damage": 0.0, "gold": 0.0, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.15, "nap": 0.0, "combo": 0.0},
		{"id": "never_wake", "branch": "AUTOMATION", "name": "Never Wake", "description": "Auto-attack continues at Comfort 0.", "cost": 4, "requires": ["night_shift"], "damage": 0.0, "gold": 0.0, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0, "special": "never_wake"},
		{"id": "better_pillow", "branch": "LAZINESS", "name": "Better Pillow", "description": "+0.10 Lazy Power.", "cost": 1, "requires": [], "damage": 0.0, "gold": 0.0, "offline": 0.0, "crit": 0.0, "lazy_power": 0.1, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0},
		{"id": "longer_naps", "branch": "LAZINESS", "name": "Longer Naps", "description": "Nap Time lasts 5s longer.", "cost": 2, "requires": ["better_pillow"], "damage": 0.0, "gold": 0.0, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 5.0, "combo": 0.0},
		{"id": "remote_sword", "branch": "LAZINESS", "name": "Remote Sword", "description": "The sword works while you do nothing.", "cost": 4, "requires": ["longer_naps"], "damage": 0.0, "gold": 0.0, "offline": 0.0, "crit": 0.0, "lazy_power": 0.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0, "special": "remote_sword"},
		{"id": "ultimate_laziness", "branch": "LAZINESS", "name": "Ultimate Laziness", "description": "The final form of not trying. +1.00 Lazy Power, +100% damage, +100% gold.", "cost": 15, "requires": ["remote_sword"], "damage": 1.0, "gold": 1.0, "offline": 0.0, "crit": 0.0, "lazy_power": 1.0, "auto": 0.0, "helper": 0.0, "nap": 0.0, "combo": 0.0, "min_highest_stage": 200, "min_prestige": 1},
	]


static func by_id(id: String) -> Dictionary:
	for node in all():
		if String(node["id"]) == id:
			return node
	return {}


static func branches() -> Array[String]:
	return ["COMBAT", "ECONOMY", "AUTOMATION", "LAZINESS"]
