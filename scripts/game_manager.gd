extends Node

signal gold_changed(new_gold: float)
signal stage_changed(new_stage: int)
signal stats_changed
signal enemy_spawned(enemy: Node)
signal enemy_hp_changed(current_hp: float, max_hp: float)
signal upgrades_changed
signal attack_ready_changed(is_ready: bool)
signal hit_landed(amount: float, is_crit: bool, is_magic: bool)
signal combo_changed(combo_count: int)
signal comfort_changed(current: float, maximum: float)
signal skill_state_changed
signal event_offered(event: Dictionary)
signal event_cleared
signal announcement(text: String)
signal gold_popup(amount: float)
signal achievement_unlocked(id: String)
signal hero_hp_changed(current_hp: float, max_hp: float)
signal combat_paused_changed(is_paused: bool)
signal enemy_state_changed(state_name: String)

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const EnemyCatalog := preload("res://data/enemy_catalog.gd")
const WorldCatalog := preload("res://data/world_catalog.gd")
const BedCatalog := preload("res://data/bed_catalog.gd")
const WeaponCatalog := preload("res://data/weapon_catalog.gd")
const HelperCatalog := preload("res://data/helper_catalog.gd")
const SkillCatalog := preload("res://data/skill_catalog.gd")
const QuestCatalog := preload("res://data/quest_catalog.gd")
const AchievementCatalog := preload("res://data/achievement_catalog.gd")
const TreeCatalog := preload("res://data/tree_catalog.gd")
const ContentCatalog := preload("res://data/content_catalog.gd")
const SaveManager := preload("res://scripts/save_manager.gd")
const CombatMath := preload("res://scripts/combat_math.gd")
const BALANCE := preload("res://data/balance.tres")

const SAVE_VERSION := 2

var gold: float = 0.0
var stage: int = 1
var highest_stage: int = 1
var total_damage: float = 0.0
var total_kills: float = 0.0
var total_upgrades_bought: int = 0
var play_time: float = 0.0

var hero_damage: float = 1.0
var damage_level: int = 0
var hp_regen_level: int = 0
var auto_attack_unlocked: bool = false
var pillow_level: int = 0
var lazy_power_quests: float = 0.0
var lazy_power_achievements: float = 0.0

var warrior_count: int = 0
var helper_levels: Dictionary = {}
var bed_level: int = 0
var equipped_weapon: String = "wooden"
var weapon_levels: Dictionary = {"wooden": 1}

var combo_count: int = 0
var hero_comfort: float = 100.0
var claimed_quests: Array = []
var quest_kills: float = 0.0
var bosses_without_manual: int = 0
var unlocked_achievements: Array = []

var lazy_tokens: int = 0
var prestige_count: int = 0
var prestige_levels: Dictionary = {}
var tree_nodes: Array = []

var _hero: Node2D
var _combat_area: Node2D
var _spawn_point: Node2D
var _hit_point: Node2D
var _enemy_host: Node2D
var _stage_banner: Label
var _helper_slots: Node2D
var _current_enemy: Node2D
var current_enemy: Node2D:
	get:
		return _current_enemy
var _attack_ready: bool = true
var _combat_paused: bool = false
var _spawn_deferred: bool = false
var _pending_spawn_generation: int = 0
var _manual_attack_timer: Timer
var _auto_attack_timer: Timer
var _helper_timer: Timer
var _combo_timer: Timer
var _autosave_timer: Timer
var _spawn_timer: Timer
var _down_timer: Timer

var _skill_cd: Dictionary = {}
var _nap_left: float = 0.0
var _do_nothing_left: float = 0.0
var _do_nothing_burst: bool = false
var _freeze_left: float = 0.0
var _kill_gold_mult: float = 1.0
var _manual_hits_this_enemy: int = 0
var _time_without_manual: float = 0.0
var _retaliate_cd: float = 0.0
var _event_cd: float = 0.0
var _pending_event: Dictionary = {}
var _pending_event_enemy: Dictionary = {}
var _napping: bool = false
var _last_save_unix: float = 0.0
var _spawn_generation: int = 0
var _achievement_tick: float = 0.0
var _hp_regen_acc: float = 0.0
var _session_active: bool = false
var _game_paused: bool = false


func _ready() -> void:
	_init_helpers()
	hero_comfort = BALANCE.hero_max_comfort
	_manual_attack_timer = _make_timer(get_attack_cooldown(), _on_manual_attack_timeout, false)
	_auto_attack_timer = _make_timer(get_auto_interval(), _on_auto_attack_timeout, true)
	_helper_timer = _make_timer(BALANCE.helper_tick_interval, _on_helper_timeout, true)
	_combo_timer = _make_timer(get_combo_timeout(), _on_combo_timeout, false)
	_autosave_timer = _make_timer(BALANCE.autosave_interval, _on_autosave_timeout, true)
	_spawn_timer = _make_timer(BALANCE.enemy_spawn_delay, _on_spawn_timeout, false)
	_down_timer = _make_timer(BALANCE.hero_recovery_time, _on_hero_down_timeout, false)


func _process(delta: float) -> void:
	if not _session_active:
		return
	play_time += delta
	_time_without_manual += delta
	_retaliate_cd = maxf(0.0, _retaliate_cd - delta)
	_event_cd = maxf(0.0, _event_cd - delta)
	_tick_skills(delta)
	_tick_comfort(delta)
	_tick_hero_regen(delta)
	_achievement_tick += delta
	if _achievement_tick >= 1.0:
		_achievement_tick = 0.0
		_check_timed_achievements()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _session_active:
		save_game()


func has_save() -> bool:
	return SaveManager.has_save()


func begin_session() -> void:
	_session_active = true
	set_game_paused(false)
	if _helper_timer:
		_helper_timer.start()
	if _autosave_timer:
		_autosave_timer.start()


func end_session() -> void:
	if _session_active:
		save_game()
	set_game_paused(false)
	_session_active = false
	_stop_session_timers()
	_unbind_world()


func _stop_session_timers() -> void:
	if _auto_attack_timer:
		_auto_attack_timer.stop()
	if _spawn_timer:
		_spawn_timer.stop()
	if _down_timer:
		_down_timer.stop()
	if _combo_timer:
		_combo_timer.stop()
	if _helper_timer:
		_helper_timer.stop()
	if _autosave_timer:
		_autosave_timer.stop()
	if _manual_attack_timer:
		_manual_attack_timer.stop()


func _unbind_world() -> void:
	_current_enemy = null
	_hero = null
	_combat_area = null
	_spawn_point = null
	_hit_point = null
	_enemy_host = null
	_stage_banner = null
	_helper_slots = null


func new_game() -> void:
	SaveManager.delete_save()
	gold = 0.0
	stage = 1
	highest_stage = 1
	total_damage = 0.0
	total_kills = 0.0
	total_upgrades_bought = 0
	play_time = 0.0
	hero_damage = 1.0
	damage_level = 0
	hp_regen_level = 0
	auto_attack_unlocked = false
	pillow_level = 0
	lazy_power_quests = 0.0
	lazy_power_achievements = 0.0
	warrior_count = 0
	helper_levels = {}
	_init_helpers()
	bed_level = 0
	equipped_weapon = "wooden"
	weapon_levels = {"wooden": 1}
	combo_count = 0
	hero_comfort = BALANCE.hero_max_comfort
	claimed_quests = []
	quest_kills = 0.0
	bosses_without_manual = 0
	unlocked_achievements = []
	lazy_tokens = 0
	prestige_count = 0
	prestige_levels = {}
	tree_nodes = []
	_attack_ready = true
	_combat_paused = false
	_spawn_deferred = false
	_pending_spawn_generation = 0
	_skill_cd.clear()
	_nap_left = 0.0
	_do_nothing_left = 0.0
	_do_nothing_burst = false
	_freeze_left = 0.0
	_kill_gold_mult = 1.0
	_manual_hits_this_enemy = 0
	_time_without_manual = 0.0
	_retaliate_cd = 0.0
	_event_cd = 0.0
	_pending_event = {}
	_pending_event_enemy = {}
	_napping = false
	_last_save_unix = 0.0
	_spawn_generation = 0
	_achievement_tick = 0.0
	_hp_regen_acc = 0.0
	_session_active = false
	set_game_paused(false)
	if _current_enemy and is_instance_valid(_current_enemy):
		_current_enemy.queue_free()
	_current_enemy = null
	_stop_session_timers()
	_unbind_world()


func bind_world(combat_area: Node2D) -> void:
	_combat_area = combat_area
	_hero = combat_area.get_node_or_null("HeroPosition/Hero")
	_spawn_point = combat_area.get_node_or_null("EnemySpawnPoint")
	_hit_point = combat_area.get_node_or_null("HeroHitPoint")
	_enemy_host = combat_area.get_node_or_null("EnemyHost")
	_stage_banner = combat_area.get_node_or_null("StageBanner")
	_helper_slots = combat_area.get_node_or_null("HelperSlots")
	_bind_hero_vitals()
	_apply_bed_visual()
	_update_stage_banner()
	_refresh_helper_visuals()
	spawn_enemy()
	_apply_automation()
	_emit_all()


func is_combat_paused() -> bool:
	return _combat_paused


func is_game_paused() -> bool:
	return _game_paused


func set_game_paused(paused: bool) -> void:
	_game_paused = paused
	get_tree().paused = paused


func get_recovery_time_left() -> float:
	if not _combat_paused or _down_timer == null:
		return 0.0
	return _down_timer.time_left


func get_death_checkpoint_stage() -> int:
	var interval := maxi(1, BALANCE.death_checkpoint_interval)
	return floori(float(stage - 1) / float(interval)) * interval + 1


func pause_combat() -> void:
	if _combat_paused:
		return
	_combat_paused = true
	announcement.emit("TOO LAZY TO DIE...")
	combat_paused_changed.emit(true)
	skill_state_changed.emit()
	attack_ready_changed.emit(false)
	_down_timer.wait_time = maxf(0.05, BALANCE.hero_recovery_time)
	_down_timer.start()
	_play_sfx("hero_down")


func resume_combat() -> void:
	if not _combat_paused:
		return
	_combat_paused = false
	if _down_timer:
		_down_timer.stop()
	combat_paused_changed.emit(false)
	skill_state_changed.emit()
	attack_ready_changed.emit(_attack_ready)
	if _spawn_deferred:
		_spawn_deferred = false
		spawn_enemy()


func is_enemy_frozen() -> bool:
	return _freeze_left > 0.0


func add_gold(amount: float) -> void:
	if amount <= 0.0:
		return
	gold += amount
	gold_changed.emit(gold)


func try_spend_gold(amount: float) -> bool:
	if amount < 0.0 or gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func try_spend_tokens(amount: int) -> bool:
	if amount < 0 or lazy_tokens < amount:
		return false
	lazy_tokens -= amount
	upgrades_changed.emit()
	stats_changed.emit()
	return true


func advance_stage() -> void:
	stage += 1
	if stage > highest_stage:
		highest_stage = stage
	stage_changed.emit(stage)
	_refresh_quests()


func register_kill() -> void:
	total_kills += 1.0
	quest_kills += 1.0
	stats_changed.emit()
	_refresh_quests()
	_refresh_achievements()


func register_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	total_damage += amount
	stats_changed.emit()


func get_lazy_power() -> float:
	return 1.0 + float(pillow_level) * BALANCE.pillow_lazy_power + lazy_power_quests + lazy_power_achievements + _tree_stat("lazy_power")


func get_crit_chance() -> float:
	return BALANCE.crit_chance + float(prestige_levels.get("perm_crit", 0)) * 0.01 + _tree_stat("crit")


func get_crit_damage() -> float:
	return BALANCE.crit_damage * (1.0 + _tree_stat("crit_damage"))


func get_damage_upgrade_cost() -> float:
	return CombatMath.scaled_cost(BALANCE.damage_upgrade_base_cost, damage_level, BALANCE.upgrade_cost_scaling)


func get_hp_regen_upgrade_cost() -> float:
	return CombatMath.scaled_cost(BALANCE.hp_regen_upgrade_base_cost, hp_regen_level, BALANCE.upgrade_cost_scaling)


func get_hero_hp_regen() -> float:
	return float(hp_regen_level) * BALANCE.hp_regen_per_level


func get_pillow_cost() -> float:
	return CombatMath.scaled_cost(BALANCE.pillow_base_cost, pillow_level, BALANCE.upgrade_cost_scaling)


func get_auto_attack_cost() -> float:
	return BALANCE.auto_attack_cost


func get_warrior_cost() -> float:
	return get_helper_cost("squire")


func get_warrior_dps() -> float:
	return get_helper_dps("squire")


func get_attack_cooldown() -> float:
	var cooldown := BALANCE.attack_cooldown
	if _weapon_special() == "slow_heavy":
		cooldown *= 2.2
	return cooldown


func get_auto_interval() -> float:
	var interval := BALANCE.auto_attack_interval
	if _weapon_special() == "auto":
		interval *= 0.75
	interval *= maxf(0.4, 1.0 - _tree_stat("auto"))
	return interval


func get_combo_timeout() -> float:
	return BALANCE.combo_timeout + _tree_stat("combo")


func get_bed() -> Dictionary:
	return BedCatalog.at(bed_level)


func get_weapon_damage() -> float:
	var weapon := WeaponCatalog.by_id(equipped_weapon)
	var level := int(weapon_levels.get(equipped_weapon, 0))
	return float(weapon.get("damage_per_level", 0.0)) * float(maxi(0, level))


func get_blacksmith_mult() -> float:
	return 1.0 + float(helper_levels.get("healer", 0)) * 0.01 + float(helper_levels.get("blacksmith", 0)) * float(HelperCatalog.by_id("blacksmith").get("base_value", 0.04))


func get_butler_mult() -> float:
	var helper := HelperCatalog.by_id("butler")
	return 1.0 + float(helper_levels.get("butler", 0)) * float(helper.get("base_value", 0.05))


func get_bed_gold_mult() -> float:
	return float(get_bed().get("gold_mult", 1.0))


func get_bed_auto_mult() -> float:
	return float(get_bed().get("auto_mult", 1.0))


func get_prestige_damage_mult() -> float:
	return 1.0 + float(prestige_levels.get("perm_damage", 0)) * 0.05 + _tree_stat("damage")


func get_prestige_gold_mult() -> float:
	return 1.0 + float(prestige_levels.get("perm_gold", 0)) * 0.05 + _tree_stat("gold")


func get_world() -> Dictionary:
	return WorldCatalog.for_stage(stage)


func get_gold_multiplier() -> float:
	return get_lazy_power() * get_bed_gold_mult() * get_butler_mult() * float(get_world().get("gold_mult", 1.0)) * get_prestige_gold_mult()


func get_hit_multiplier(is_auto: bool) -> float:
	var mult := get_lazy_power()
	mult *= CombatMath.combo_multiplier(combo_count)
	mult *= 2.0 if _nap_left > 0.0 else 1.0
	if is_auto:
		mult *= get_bed_auto_mult()
	mult *= get_prestige_damage_mult()
	return mult


func get_hero_base_damage() -> float:
	return CombatMath.as_int_damage(hero_damage + get_weapon_damage() * get_blacksmith_mult())


func get_helper_level(id: String) -> int:
	return int(helper_levels.get(id, 0))


func get_helper_dps(id: String) -> float:
	var helper := HelperCatalog.by_id(id)
	if helper.is_empty():
		return 0.0
	var role := String(helper.get("role", ""))
	if role != "dps" and role != "ranged_dps" and role != "magic_dps":
		return 0.0
	var level := get_helper_level(id)
	return float(level) * float(helper.get("base_value", 0.0)) * BALANCE.dps_scaling * (1.0 + _tree_stat("helper"))


func get_helper_cost(id: String) -> float:
	var helper := HelperCatalog.by_id(id)
	var base := float(helper.get("base_cost", 500.0))
	if id == "squire":
		base = BALANCE.warrior_base_cost
	return CombatMath.scaled_cost(base, get_helper_level(id), BALANCE.upgrade_cost_scaling)


func get_total_helper_dps() -> float:
	var total := 0.0
	for helper in HelperCatalog.all():
		total += get_helper_dps(String(helper["id"]))
	return total


func get_weapon_upgrade_cost(id: String) -> float:
	var weapon := WeaponCatalog.by_id(id)
	var level := int(weapon_levels.get(id, 0))
	return CombatMath.scaled_cost(float(weapon.get("upgrade_base_cost", 25.0)), maxi(0, level), BALANCE.upgrade_cost_scaling)


func get_skill_cooldown(id: String) -> float:
	return float(_skill_cd.get(id, 0.0))


func is_skill_ready(id: String) -> bool:
	var skill := SkillCatalog.by_id(id)
	if skill.is_empty():
		return false
	if stage < int(skill.get("unlock_stage", 1)):
		return false
	return get_skill_cooldown(id) <= 0.0


func can_prestige() -> bool:
	return highest_stage >= BALANCE.prestige_unlock_stage


func get_prestige_token_reward() -> int:
	if not can_prestige():
		return 0
	var raw := pow(float(highest_stage) / 40.0, 1.25) * BALANCE.prestige_scaling
	return maxi(1, int(floor(raw)))


func try_manual_attack() -> void:
	if is_game_paused() or is_combat_paused():
		return
	if not _attack_ready:
		return
	if _do_nothing_left > 0.0:
		return
	if _napping and not _can_act_while_sleeping():
		return
	if not _deal_hero_damage(true):
		return
	_time_without_manual = 0.0
	_manual_hits_this_enemy += 1
	combo_count += 1
	combo_changed.emit(combo_count)
	_combo_timer.wait_time = get_combo_timeout()
	_combo_timer.start()
	if _current_enemy and is_instance_valid(_current_enemy) and String(_current_enemy.mechanic) == "sleep_resist":
		if _manual_hits_this_enemy >= BALANCE.sleep_hits_to_wake:
			_current_enemy.set_status("AWAKE")
	_attack_ready = false
	attack_ready_changed.emit(false)
	_manual_attack_timer.wait_time = get_attack_cooldown()
	_manual_attack_timer.start()
	_play_sfx("attack")


func buy_damage_upgrade() -> bool:
	if not try_spend_gold(get_damage_upgrade_cost()):
		return false
	damage_level += 1
	hero_damage += 1.0
	_on_upgrade_bought("LEVEL UP!")
	if _hero:
		_hero.play_animation("level_up")
	return true


func buy_hp_regen_upgrade() -> bool:
	if not try_spend_gold(get_hp_regen_upgrade_cost()):
		return false
	hp_regen_level += 1
	if _hero:
		_hero.hp_regen = get_hero_hp_regen()
	_on_upgrade_bought("RESTED!")
	return true


func buy_pillow() -> bool:
	if not try_spend_gold(get_pillow_cost()):
		return false
	pillow_level += 1
	_on_upgrade_bought("LAZIER!")
	return true


func buy_auto_attack() -> bool:
	if auto_attack_unlocked:
		return false
	if not try_spend_gold(get_auto_attack_cost()):
		return false
	auto_attack_unlocked = true
	_apply_automation()
	_on_upgrade_bought("")
	return true


func buy_warrior() -> bool:
	return buy_helper("squire")


func buy_helper(id: String) -> bool:
	if HelperCatalog.by_id(id).is_empty():
		return false
	if not try_spend_gold(get_helper_cost(id)):
		return false
	helper_levels[id] = get_helper_level(id) + 1
	if id == "squire":
		warrior_count = get_helper_level("squire")
	_on_upgrade_bought("")
	return true


func upgrade_bed() -> bool:
	var nxt := BedCatalog.next(bed_level)
	if nxt.is_empty():
		return false
	if not try_spend_gold(float(nxt["cost"])):
		return false
	bed_level += 1
	_apply_bed_visual()
	_on_upgrade_bought("NEW BED!")
	return true


func unlock_or_upgrade_weapon(id: String) -> bool:
	var weapon := WeaponCatalog.by_id(id)
	if weapon.is_empty():
		return false
	var level := int(weapon_levels.get(id, 0))
	if level <= 0 and stage < int(weapon.get("unlock_stage", 1)):
		return false
	if not try_spend_gold(get_weapon_upgrade_cost(id)):
		return false
	weapon_levels[id] = level + 1
	if equipped_weapon == "":
		equipped_weapon = id
	_apply_automation()
	_on_upgrade_bought("")
	return true


func equip_weapon(id: String) -> bool:
	if int(weapon_levels.get(id, 0)) <= 0:
		return false
	equipped_weapon = id
	_apply_automation()
	upgrades_changed.emit()
	stats_changed.emit()
	return true


func try_skill(id: String) -> bool:
	if is_game_paused() or is_combat_paused():
		return false
	if not is_skill_ready(id):
		return false
	var skill := SkillCatalog.by_id(id)
	match id:
		"lazy_slap":
			if not _deal_skill_hit(5.0):
				return false
		"nap_time":
			_nap_left = 10.0 + _tree_stat("nap")
			announcement.emit("NAP TIME")
		"do_nothing":
			_do_nothing_left = 5.0
			announcement.emit("DOING NOTHING...")
		"bedquake":
			if not _deal_skill_hit(8.0):
				return false
			announcement.emit("BEDQUAKE!")
		"procrastination":
			if _current_enemy == null:
				return false
			_freeze_left = 4.0
			_kill_gold_mult = 2.0
			if _current_enemy.has_method("set_status"):
				_current_enemy.set_status("PROCRASTINATING...")
			announcement.emit("PROCRASTINATION")
		_:
			return false
	_skill_cd[id] = float(skill.get("cooldown", 30.0))
	skill_state_changed.emit()
	_play_sfx("upgrade")
	return true


func accept_event() -> void:
	if _pending_event.is_empty():
		return
	var event := _pending_event
	_pending_event = {}
	event_cleared.emit()
	var kind := String(event.get("kind", ""))
	if kind == "gold":
		var def := EnemyCatalog.for_stage(stage)
		var amount := float(def["gold_reward"]) * float(event.get("gold_mult", 8.0)) * get_gold_multiplier()
		add_gold(amount)
		gold_popup.emit(amount)
		announcement.emit(String(event.get("name", "Reward")))
		_play_sfx("coin")
		return
	_pending_event_enemy = EnemyCatalog.event_enemy(String(event["id"]), stage)
	_spawn_generation += 1
	if _current_enemy and is_instance_valid(_current_enemy):
		_current_enemy.queue_free()
		_current_enemy = null
	spawn_enemy()


func ignore_event() -> void:
	_pending_event = {}
	_pending_event_enemy = {}
	event_cleared.emit()


func claim_quest(id: String) -> bool:
	var quest := QuestCatalog.by_id(id)
	if quest.is_empty() or not is_quest_complete(id):
		return false
	if not bool(quest.get("repeatable", false)) and claimed_quests.has(id):
		return false
	if bool(quest.get("repeatable", false)):
		if id == "kill_10":
			quest_kills = maxf(0.0, quest_kills - float(quest["target"]))
	else:
		claimed_quests.append(id)
	var gold_reward := float(quest.get("gold", 0.0))
	if gold_reward > 0.0:
		add_gold(gold_reward)
		gold_popup.emit(gold_reward)
	var lp := float(quest.get("lazy_power", 0.0))
	if lp > 0.0:
		lazy_power_quests += lp
	upgrades_changed.emit()
	stats_changed.emit()
	announcement.emit("QUEST COMPLETE")
	_play_sfx("upgrade")
	return true


func is_quest_complete(id: String) -> bool:
	var quest := QuestCatalog.by_id(id)
	if quest.is_empty():
		return false
	if not bool(quest.get("repeatable", false)) and claimed_quests.has(id):
		return false
	return _quest_progress(quest) >= float(quest.get("target", 1.0))


func quest_progress_text(id: String) -> String:
	var quest := QuestCatalog.by_id(id)
	var current := _quest_progress(quest)
	var target := float(quest.get("target", 1.0))
	return "%s / %s" % [str(int(current)), str(int(target))]


func buy_prestige_upgrade(id: String) -> bool:
	var found: Dictionary = {}
	for item in ContentCatalog.shop():
		if String(item["id"]) == id:
			found = item
			break
	if found.is_empty():
		return false
	var level := int(prestige_levels.get(id, 0))
	var cost := int(found.get("base_cost", 1)) + level
	if not try_spend_tokens(cost):
		return false
	prestige_levels[id] = level + 1
	upgrades_changed.emit()
	stats_changed.emit()
	_play_sfx("upgrade")
	return true


func buy_tree_node(id: String) -> bool:
	var node := TreeCatalog.by_id(id)
	if node.is_empty() or tree_nodes.has(id):
		return false
	for req in node.get("requires", []):
		if not tree_nodes.has(req):
			return false
	if highest_stage < int(node.get("min_highest_stage", 0)):
		return false
	if prestige_count < int(node.get("min_prestige", 0)):
		return false
	if not try_spend_tokens(int(node.get("cost", 1))):
		return false
	tree_nodes.append(id)
	upgrades_changed.emit()
	stats_changed.emit()
	announcement.emit(String(node.get("name", "Unlocked")))
	_play_sfx("upgrade")
	return true


func do_prestige() -> bool:
	if not can_prestige():
		return false
	var tokens := get_prestige_token_reward()
	lazy_tokens += tokens
	prestige_count += 1
	gold = 0.0
	stage = 1
	hero_damage = 1.0
	damage_level = 0
	hp_regen_level = 0
	auto_attack_unlocked = false
	pillow_level = 0
	combo_count = 0
	warrior_count = 0
	_init_helpers()
	equipped_weapon = "wooden"
	weapon_levels = {"wooden": 1}
	_skill_cd.clear()
	_nap_left = 0.0
	_do_nothing_left = 0.0
	_do_nothing_burst = false
	_kill_gold_mult = 1.0
	hero_comfort = BALANCE.hero_max_comfort
	_napping = false
	_combat_paused = false
	_spawn_deferred = false
	_hp_regen_acc = 0.0
	if _down_timer:
		_down_timer.stop()
	_bind_hero_vitals()
	_apply_automation()
	if _enemy_host:
		spawn_enemy()
	_emit_all()
	announcement.emit("PRESTIGE!")
	_play_sfx("prestige")
	save_game()
	return true


func spawn_enemy() -> void:
	if _enemy_host == null:
		return
	if is_combat_paused():
		_spawn_deferred = true
		return
	_spawn_deferred = false
	if _spawn_timer:
		_spawn_timer.stop()
	if _current_enemy and is_instance_valid(_current_enemy):
		_current_enemy.queue_free()
	_current_enemy = ENEMY_SCENE.instantiate()
	_enemy_host.add_child(_current_enemy)
	if _spawn_point:
		_current_enemy.global_position = _spawn_point.global_position
	_current_enemy.died.connect(_on_enemy_died)
	_current_enemy.hp_changed.connect(_on_enemy_hp_changed)
	if _current_enemy.has_signal("attacked"):
		_current_enemy.attacked.connect(_on_enemy_attacked)
	if _current_enemy.has_signal("state_changed"):
		_current_enemy.state_changed.connect(_on_enemy_state_changed)
	var definition: Dictionary
	if not _pending_event_enemy.is_empty():
		definition = _pending_event_enemy
		_pending_event_enemy = {}
	else:
		definition = EnemyCatalog.for_stage(stage)
	_current_enemy.setup(definition)
	var target := Vector2.ZERO
	if _hit_point:
		target = _hit_point.global_position
	elif _hero:
		target = _hero.global_position
	if _current_enemy.has_method("begin_approach"):
		_current_enemy.begin_approach(target)
	_manual_hits_this_enemy = 0
	_kill_gold_mult = 1.0
	if bool(definition.get("is_boss", false)):
		_play_sfx("boss")
	enemy_spawned.emit(_current_enemy)
	enemy_hp_changed.emit(_current_enemy.current_hp, _current_enemy.max_hp)
	enemy_state_changed.emit(_current_enemy.state_name() if _current_enemy.has_method("state_name") else "")
	_update_stage_banner()


func save_game() -> void:
	if not _session_active:
		return
	_last_save_unix = Time.get_unix_time_from_system()
	SaveManager.save_game({
		"save_version": SAVE_VERSION,
		"gold": gold,
		"stage": stage,
		"highest_stage": highest_stage,
		"hero_damage": hero_damage,
		"damage_level": damage_level,
		"hp_regen_level": hp_regen_level,
		"auto_attack_unlocked": auto_attack_unlocked,
		"warrior_count": get_helper_level("squire"),
		"helper_levels": helper_levels,
		"pillow_level": pillow_level,
		"lazy_power_quests": lazy_power_quests,
		"lazy_power_achievements": lazy_power_achievements,
		"bed_level": bed_level,
		"equipped_weapon": equipped_weapon,
		"weapon_levels": weapon_levels,
		"total_damage": total_damage,
		"total_kills": total_kills,
		"total_upgrades_bought": total_upgrades_bought,
		"play_time": play_time,
		"claimed_quests": claimed_quests,
		"quest_kills": quest_kills,
		"bosses_without_manual": bosses_without_manual,
		"unlocked_achievements": unlocked_achievements,
		"lazy_tokens": lazy_tokens,
		"prestige_count": prestige_count,
		"prestige_levels": prestige_levels,
		"tree_nodes": tree_nodes,
		"last_save_unix": _last_save_unix,
	})


func load_game() -> void:
	var data := SaveManager.load_game()
	if data.is_empty():
		_last_save_unix = Time.get_unix_time_from_system()
		return
	gold = float(data.get("gold", 0.0))
	stage = int(data.get("stage", 1))
	highest_stage = int(data.get("highest_stage", stage))
	hero_damage = float(data.get("hero_damage", 1.0))
	damage_level = int(data.get("damage_level", 0))
	hp_regen_level = int(data.get("hp_regen_level", 0))
	auto_attack_unlocked = bool(data.get("auto_attack_unlocked", false))
	pillow_level = int(data.get("pillow_level", 0))
	lazy_power_quests = float(data.get("lazy_power_quests", 0.0))
	lazy_power_achievements = float(data.get("lazy_power_achievements", 0.0))
	bed_level = int(data.get("bed_level", 0))
	equipped_weapon = String(data.get("equipped_weapon", "wooden"))
	weapon_levels = _as_dict(data.get("weapon_levels", {"wooden": 1}))
	if int(weapon_levels.get("wooden", 0)) < 1:
		weapon_levels["wooden"] = 1
	helper_levels = _as_dict(data.get("helper_levels", {}))
	_init_helpers()
	var saved_squire := int(data.get("warrior_count", 0))
	if get_helper_level("squire") == 0 and saved_squire > 0:
		helper_levels["squire"] = saved_squire
	warrior_count = get_helper_level("squire")
	total_damage = float(data.get("total_damage", 0.0))
	total_kills = float(data.get("total_kills", 0.0))
	total_upgrades_bought = int(data.get("total_upgrades_bought", 0))
	play_time = float(data.get("play_time", 0.0))
	claimed_quests = _as_array(data.get("claimed_quests", []))
	quest_kills = float(data.get("quest_kills", 0.0))
	bosses_without_manual = int(data.get("bosses_without_manual", 0))
	unlocked_achievements = _as_array(data.get("unlocked_achievements", []))
	lazy_tokens = int(data.get("lazy_tokens", 0))
	prestige_count = int(data.get("prestige_count", 0))
	prestige_levels = _as_dict(data.get("prestige_levels", {}))
	tree_nodes = _as_array(data.get("tree_nodes", []))
	if stage < 1:
		stage = 1
	if highest_stage < stage:
		highest_stage = stage
	hero_comfort = BALANCE.hero_max_comfort
	_napping = false
	_combat_paused = false
	_spawn_deferred = false
	_hp_regen_acc = 0.0
	if _down_timer:
		_down_timer.stop()
	_bind_hero_vitals()
	_last_save_unix = Time.get_unix_time_from_system()
	_apply_automation()
	if _enemy_host:
		spawn_enemy()
	_emit_all()


func _deal_hero_damage(is_manual: bool) -> bool:
	if _hero:
		_hero.play_animation("attack")
	return _deal_damage(get_hero_base_damage(), get_hit_multiplier(not is_manual), false)


func _deal_skill_hit(power: float) -> bool:
	return _deal_damage(get_hero_base_damage() * power, get_hit_multiplier(false), false)


func _deal_damage(base: float, multiplier: float, is_magic: bool) -> bool:
	if is_combat_paused():
		return false
	if base <= 0.0:
		return false
	if _current_enemy == null or not is_instance_valid(_current_enemy):
		return false
	if _current_enemy.current_hp <= 0.0:
		return false
	if _do_nothing_burst:
		multiplier *= 6.0
		_do_nothing_burst = false
		announcement.emit("MAXIMUM LAZINESS")
	var resist := _incoming_resist()
	var hit: Dictionary = CombatMath.compute_hit(base, multiplier, get_crit_chance(), get_crit_damage(), resist)
	var amount := float(hit["amount"])
	var is_crit := bool(hit["is_crit"])
	var applied := minf(amount, _current_enemy.current_hp)
	_current_enemy.take_damage(amount, is_crit)
	register_damage(applied)
	hit_landed.emit(amount, is_crit, is_magic)
	if is_crit:
		_play_sfx("critical")
	_try_retaliate()
	return true


func _on_enemy_died() -> void:
	var reward := 0.0
	var was_boss := false
	if _current_enemy and is_instance_valid(_current_enemy):
		reward = float(_current_enemy.gold_reward) * get_gold_multiplier() * _kill_gold_mult
		was_boss = bool(_current_enemy.is_boss)
	if was_boss and _manual_hits_this_enemy <= 0:
		bosses_without_manual += 1
	add_gold(reward)
	gold_popup.emit(reward)
	_play_sfx("enemy_death")
	_play_sfx("coin")
	register_kill()
	advance_stage()
	_maybe_roll_event()
	_update_stage_banner()
	if _current_enemy and is_instance_valid(_current_enemy):
		_current_enemy.queue_free()
	_current_enemy = null
	enemy_hp_changed.emit(0.0, 0.0)
	enemy_state_changed.emit("")
	_spawn_generation += 1
	_pending_spawn_generation = _spawn_generation
	_spawn_timer.wait_time = maxf(0.05, BALANCE.enemy_spawn_delay)
	_spawn_timer.start()


func _on_spawn_timeout() -> void:
	if _pending_spawn_generation != _spawn_generation:
		return
	if is_combat_paused():
		_spawn_deferred = true
		return
	spawn_enemy()


func _on_enemy_hp_changed(current_hp: float, max_hp: float) -> void:
	enemy_hp_changed.emit(current_hp, max_hp)


func _on_enemy_state_changed(state_name: String) -> void:
	enemy_state_changed.emit(state_name)


func _on_enemy_attacked(amount: float) -> void:
	if is_combat_paused():
		return
	if _hero and _hero.has_method("take_damage"):
		_hero.take_damage(CombatMath.as_int_damage(amount))


func _on_manual_attack_timeout() -> void:
	_attack_ready = true
	attack_ready_changed.emit(_attack_ready and not is_combat_paused())


func _on_auto_attack_timeout() -> void:
	if is_combat_paused():
		return
	if not _has_auto_attack():
		return
	if _do_nothing_left > 0.0 and not _can_act_while_sleeping():
		return
	if _napping and not _can_act_while_sleeping():
		return
	_deal_hero_damage(false)


func _on_helper_timeout() -> void:
	if is_combat_paused():
		return
	var physical := get_helper_dps("squire") + get_helper_dps("archer")
	var magic := get_helper_dps("mage")
	var helper_mult := get_hit_multiplier(true)
	if physical > 0.0:
		_deal_damage(physical, helper_mult, false)
	if magic > 0.0:
		_deal_damage(magic, helper_mult, true)
	var healer := get_helper_level("healer")
	if healer > 0:
		_add_comfort(float(healer) * float(HelperCatalog.by_id("healer").get("base_value", 1.5)))


func _on_combo_timeout() -> void:
	combo_count = 0
	combo_changed.emit(combo_count)


func _on_autosave_timeout() -> void:
	if not _session_active:
		return
	save_game()


func _apply_automation() -> void:
	_auto_attack_timer.wait_time = get_auto_interval()
	if _has_auto_attack():
		if _auto_attack_timer.is_stopped():
			_auto_attack_timer.start()
	else:
		_auto_attack_timer.stop()


func _has_auto_attack() -> bool:
	if auto_attack_unlocked:
		return true
	if _weapon_special() == "auto":
		return true
	return false


func _can_act_while_sleeping() -> bool:
	if _weapon_special() == "telekinetic":
		return true
	if tree_nodes.has("never_wake") or tree_nodes.has("remote_sword"):
		return true
	return false


func _weapon_special() -> String:
	return String(WeaponCatalog.by_id(equipped_weapon).get("special", ""))


func _incoming_resist() -> float:
	if _current_enemy == null or not is_instance_valid(_current_enemy):
		return 1.0
	var mechanic := String(_current_enemy.mechanic)
	if mechanic == "sleep_resist" and _manual_hits_this_enemy < BALANCE.sleep_hits_to_wake:
		return BALANCE.sleep_resist_mult
	if mechanic == "retaliate_resist":
		return 0.72
	return 1.0


func _try_retaliate() -> void:
	if _current_enemy == null or not is_instance_valid(_current_enemy):
		return
	if _freeze_left > 0.0:
		return
	var mechanic := String(_current_enemy.mechanic)
	if mechanic != "retaliate" and mechanic != "retaliate_resist":
		return
	if _retaliate_cd > 0.0:
		return
	_retaliate_cd = 0.45
	var amount := BALANCE.retaliate_damage
	if mechanic == "retaliate_resist":
		amount *= 1.6
	_add_comfort(-amount)
	if _hero:
		_hero.play_animation("hit")


func _add_comfort(amount: float) -> void:
	var previous := hero_comfort
	var was_napping := _napping
	hero_comfort = clampf(hero_comfort + amount, 0.0, BALANCE.hero_max_comfort)
	if hero_comfort <= 0.0:
		_napping = true
	elif _napping and hero_comfort >= BALANCE.hero_max_comfort * 0.3:
		_napping = false
	if was_napping != _napping or absf(previous - hero_comfort) >= 0.2:
		comfort_changed.emit(hero_comfort, BALANCE.hero_max_comfort)


func _tick_comfort(delta: float) -> void:
	var regen := BALANCE.comfort_regen
	if _napping:
		regen *= 2.5
	_add_comfort(regen * delta)


func _tick_skills(delta: float) -> void:
	if is_combat_paused():
		return
	var changed := false
	for id in _skill_cd.keys():
		var left := float(_skill_cd[id]) - delta
		if left <= 0.0:
			_skill_cd[id] = 0.0
			changed = true
		else:
			_skill_cd[id] = left
	if _nap_left > 0.0:
		_nap_left = maxf(0.0, _nap_left - delta)
		if _nap_left <= 0.0:
			changed = true
	if _do_nothing_left > 0.0:
		_do_nothing_left = maxf(0.0, _do_nothing_left - delta)
		if _do_nothing_left <= 0.0:
			_do_nothing_burst = true
			announcement.emit("STILL DID NOTHING")
			changed = true
	if _freeze_left > 0.0:
		_freeze_left = maxf(0.0, _freeze_left - delta)
		if _freeze_left <= 0.0 and _current_enemy and is_instance_valid(_current_enemy) and _current_enemy.has_method("set_status"):
			_current_enemy.set_status("")
	if changed:
		skill_state_changed.emit()


func _maybe_roll_event() -> void:
	if _event_cd > 0.0 or not _pending_event.is_empty():
		return
	if randf() > BALANCE.event_chance:
		return
	var events := ContentCatalog.events()
	_pending_event = events[randi() % events.size()]
	_event_cd = BALANCE.event_cooldown
	event_offered.emit(_pending_event)


func _on_upgrade_bought(text: String) -> void:
	total_upgrades_bought += 1
	upgrades_changed.emit()
	stats_changed.emit()
	_refresh_quests()
	_refresh_helper_visuals()
	if text != "":
		announcement.emit(text)
	_play_sfx("upgrade")
	_play_sfx("level_up" if text == "LEVEL UP!" else "button_click")


func _refresh_quests() -> void:
	upgrades_changed.emit()


func _refresh_achievements() -> void:
	for item in AchievementCatalog.all():
		var id := String(item["id"])
		if unlocked_achievements.has(id):
			continue
		if not _achievement_met(item):
			continue
		unlocked_achievements.append(id)
		var gold_reward := float(item.get("gold", 0.0))
		if gold_reward > 0.0:
			add_gold(gold_reward)
		var lp := float(item.get("lazy_power", 0.0))
		if lp > 0.0:
			lazy_power_achievements += lp
		achievement_unlocked.emit(id)
		announcement.emit(String(item.get("name", "Achievement")))
		upgrades_changed.emit()
		stats_changed.emit()


func _check_timed_achievements() -> void:
	_refresh_achievements()


func _achievement_met(item: Dictionary) -> bool:
	match String(item.get("type", "")):
		"kills":
			return total_kills >= float(item.get("target", 1.0))
		"no_manual":
			return _time_without_manual >= float(item.get("target", 300.0))
		"boss_no_manual":
			return bosses_without_manual >= int(item.get("target", 1))
		"play_time":
			return play_time >= float(item.get("target", 3600.0))
		"stage":
			return highest_stage >= int(item.get("target", 1))
		_:
			return false


func _quest_progress(quest: Dictionary) -> float:
	match String(quest.get("type", "")):
		"kills":
			return quest_kills
		"stage":
			return float(highest_stage)
		"upgrades":
			return float(total_upgrades_bought)
		"boss_no_manual":
			return float(bosses_without_manual)
		_:
			return 0.0


func _tree_stat(stat: String) -> float:
	var total := 0.0
	for id in tree_nodes:
		var node := TreeCatalog.by_id(String(id))
		total += float(node.get(stat, 0.0))
	return total


func _init_helpers() -> void:
	for helper in HelperCatalog.all():
		var id := String(helper["id"])
		if not helper_levels.has(id):
			helper_levels[id] = 0


func _apply_bed_visual() -> void:
	if _hero and _hero.has_method("apply_bed_tier"):
		_hero.apply_bed_tier(bed_level, Color(get_bed().get("color", Color.WHITE)))


func _bind_hero_vitals() -> void:
	if _hero == null:
		return
	if _hero.has_method("setup_vitals"):
		_hero.setup_vitals(BALANCE.hero_max_hp, get_hero_hp_regen())
	if _hero.has_signal("hp_changed") and not _hero.hp_changed.is_connected(_on_hero_hp_changed):
		_hero.hp_changed.connect(_on_hero_hp_changed)
	if _hero.has_signal("downed") and not _hero.downed.is_connected(_on_hero_downed):
		_hero.downed.connect(_on_hero_downed)
	if _hero.has_signal("recovered") and not _hero.recovered.is_connected(_on_hero_recovered):
		_hero.recovered.connect(_on_hero_recovered)


func _tick_hero_regen(delta: float) -> void:
	if is_combat_paused():
		_hp_regen_acc = 0.0
		return
	var regen := get_hero_hp_regen()
	if regen <= 0.0 or _hero == null or not _hero.has_method("heal"):
		return
	_hp_regen_acc += regen * delta
	if _hp_regen_acc < 1.0:
		return
	var amount := floorf(_hp_regen_acc)
	_hp_regen_acc -= amount
	_hero.heal(amount)


func _on_hero_hp_changed(current_hp: float, max_hp: float) -> void:
	hero_hp_changed.emit(current_hp, max_hp)


func _on_hero_downed() -> void:
	pause_combat()


func _on_hero_down_timeout() -> void:
	if _hero and _hero.has_method("recover_from_down"):
		_hero.recover_from_down()
	else:
		_on_hero_recovered()


func _on_hero_recovered() -> void:
	stage = get_death_checkpoint_stage()
	stage_changed.emit(stage)
	_update_stage_banner()
	_spawn_deferred = false
	resume_combat()
	spawn_enemy()
	announcement.emit("RETURNING TO STAGE %s" % str(stage))


func _update_stage_banner() -> void:
	if _stage_banner:
		_stage_banner.text = "STAGE %s" % str(stage)


func _refresh_helper_visuals() -> void:
	if _helper_slots == null:
		return
	_set_helper_slot_visible("SquireSlot", get_helper_level("squire") > 0)
	_set_helper_slot_visible("ArcherSlot", get_helper_level("archer") > 0)
	_set_helper_slot_visible("MageSlot", get_helper_level("mage") > 0)


func _set_helper_slot_visible(slot_name: String, show: bool) -> void:
	var slot := _helper_slots.get_node_or_null(slot_name)
	if slot:
		slot.visible = show


func _emit_all() -> void:
	gold_changed.emit(gold)
	stage_changed.emit(stage)
	stats_changed.emit()
	upgrades_changed.emit()
	attack_ready_changed.emit(_attack_ready and not is_combat_paused())
	combo_changed.emit(combo_count)
	comfort_changed.emit(hero_comfort, BALANCE.hero_max_comfort)
	skill_state_changed.emit()
	combat_paused_changed.emit(_combat_paused)
	if _hero:
		hero_hp_changed.emit(float(_hero.current_hp), float(_hero.max_hp))
	else:
		hero_hp_changed.emit(BALANCE.hero_max_hp, BALANCE.hero_max_hp)
	_update_stage_banner()
	_refresh_helper_visuals()


func _play_sfx(id: String) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play"):
		audio.play(id)


func _as_dict(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _as_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func _make_timer(wait_time: float, callback: Callable, looping: bool) -> Timer:
	var timer := Timer.new()
	timer.wait_time = maxf(0.05, wait_time)
	timer.one_shot = not looping
	timer.autostart = false
	timer.timeout.connect(callback)
	add_child(timer)
	return timer
