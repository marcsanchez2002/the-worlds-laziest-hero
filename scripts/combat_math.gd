extends RefCounted


static func combo_multiplier(combo_count: int) -> float:
	if combo_count >= 100:
		return 2.0
	if combo_count >= 50:
		return 1.5
	if combo_count >= 25:
		return 1.25
	if combo_count >= 10:
		return 1.1
	return 1.0


static func scaled_cost(base_cost: float, level: int, multiplier: float) -> float:
	return maxf(1.0, roundf(base_cost * pow(multiplier, float(maxi(0, level)))))


static func average_crit_factor(crit_chance: float, crit_damage: float) -> float:
	var chance := clampf(crit_chance, 0.0, 0.95)
	var damage := maxf(1.0, crit_damage)
	return 1.0 + chance * (damage - 1.0)


static func as_int_damage(value: float) -> float:
	if value <= 0.0:
		return 0.0
	return maxf(1.0, roundf(value))


static func compute_hit(base_damage: float, multiplier: float, crit_chance: float, crit_damage: float, incoming_resist: float = 1.0) -> Dictionary:
	var is_crit := randf() < clampf(crit_chance, 0.0, 0.95)
	var amount := maxf(0.0, base_damage) * maxf(0.0, multiplier) * maxf(0.0, incoming_resist)
	if is_crit:
		amount *= maxf(1.0, crit_damage)
	amount = as_int_damage(amount)
	return {"amount": amount, "is_crit": is_crit}
