extends RefCounted


static func all() -> Array[Dictionary]:
	return [
		{"id": "old_mattress", "name": "Old Mattress", "gold_mult": 1.0, "auto_mult": 1.0, "cost": 0.0, "color": Color(0.55, 0.38, 0.28)},
		{"id": "comfortable", "name": "Comfortable Bed", "gold_mult": 1.05, "auto_mult": 1.0, "cost": 250.0, "color": Color(0.62, 0.44, 0.36)},
		{"id": "luxury", "name": "Luxury Bed", "gold_mult": 1.1, "auto_mult": 1.05, "cost": 1200.0, "color": Color(0.55, 0.32, 0.48)},
		{"id": "royal", "name": "Royal Bed", "gold_mult": 1.25, "auto_mult": 1.1, "cost": 6000.0, "color": Color(0.72, 0.55, 0.22)},
		{"id": "magic", "name": "Magic Bed", "gold_mult": 1.4, "auto_mult": 1.18, "cost": 25000.0, "color": Color(0.38, 0.42, 0.78)},
		{"id": "cloud", "name": "Cloud Bed", "gold_mult": 1.65, "auto_mult": 1.28, "cost": 120000.0, "color": Color(0.78, 0.88, 0.95)},
		{"id": "divine", "name": "Divine Bed", "gold_mult": 2.0, "auto_mult": 1.45, "cost": 600000.0, "color": Color(0.98, 0.9, 0.55)},
	]


static func at(level: int) -> Dictionary:
	var beds := all()
	var index := clampi(level, 0, beds.size() - 1)
	return beds[index]


static func next(level: int) -> Dictionary:
	var beds := all()
	if level + 1 >= beds.size():
		return {}
	return beds[level + 1]


static func max_level() -> int:
	return all().size() - 1
