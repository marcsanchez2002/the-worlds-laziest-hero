extends Node2D

const NumberUtil := preload("res://scripts/number_util.gd")
const FLOATING_TEXT := preload("res://scenes/ui/floating_text.tscn")

enum State { MOVING, ATTACKING, HIT, DYING, DEAD }

signal died
signal hp_changed(current_hp: float, max_hp: float)
signal attacked(amount: float)
signal state_changed(state_name: String)

var display_name: String = "Enemy"
var max_hp: float = 20.0
var current_hp: float = 20.0
var gold_reward: float = 5.0
var is_boss: bool = false
var mechanic: String = ""
var move_speed: float = 50.0
var attack_range: float = 80.0
var attack_damage: float = 1.0
var attack_cooldown: float = 2.0
var attack_timer: float = 0.0
var combat_state: State = State.MOVING

var _target_position: Vector2 = Vector2.ZERO
var _feedback_tween: Tween

@onready var visual: Node2D = $Visual
@onready var body: Polygon2D = $Visual/Body
@onready var name_label: Label = $NameLabel
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel


func setup(definition: Dictionary) -> void:
	_cache_nodes()
	display_name = String(definition.get("display_name", "Enemy"))
	max_hp = maxf(1.0, roundf(float(definition.get("max_hp", 20.0))))
	current_hp = max_hp
	gold_reward = float(definition.get("gold_reward", 5.0))
	is_boss = bool(definition.get("is_boss", false))
	mechanic = String(definition.get("mechanic", ""))
	move_speed = float(definition.get("move_speed", 50.0))
	attack_range = float(definition.get("attack_range", 80.0))
	attack_damage = maxf(1.0, roundf(float(definition.get("attack_damage", 1.0))))
	attack_cooldown = float(definition.get("attack_cooldown", 2.0))
	attack_timer = 0.0
	body.color = definition.get("color", Color(0.7, 0.7, 0.7))
	_apply_boss_visual()
	_refresh_ui()
	_set_state(State.MOVING)


func begin_approach(target: Vector2) -> void:
	_target_position = target
	if combat_state == State.DEAD or combat_state == State.DYING:
		return
	_set_state(State.MOVING)


func state_name() -> String:
	match combat_state:
		State.MOVING:
			return "APPROACHING"
		State.ATTACKING:
			return "ATTACKING"
		State.HIT:
			return "HIT"
		State.DYING:
			return "DYING"
		_:
			return "DEAD"


func take_damage(amount: float, is_crit: bool = false) -> void:
	if combat_state == State.DYING or combat_state == State.DEAD:
		return
	if current_hp <= 0.0 or amount <= 0.0:
		return
	var damage := maxf(1.0, roundf(amount))
	current_hp = maxf(0.0, roundf(current_hp - damage))
	_refresh_ui()
	play_animation("hit")
	_play_hit(damage, is_crit)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		_set_state(State.DYING)
		play_animation("death")
		_play_death()


func set_status(_text: String) -> void:
	pass


func play_animation(anim_name: String) -> void:
	_cache_nodes()
	if visual == null:
		return
	match anim_name:
		"attack":
			_lunge()
		"hit":
			pass
		"death":
			pass
		_:
			pass


func _process(delta: float) -> void:
	if combat_state == State.DEAD or combat_state == State.DYING:
		return
	if _is_paused():
		return
	match combat_state:
		State.MOVING:
			_move_towards(delta)
		State.ATTACKING:
			_tick_attack(delta)
		State.HIT:
			pass


func _move_towards(delta: float) -> void:
	var to_target := _target_position - global_position
	var dist := to_target.length()
	if dist <= attack_range:
		global_position = _stop_position(to_target, dist)
		_set_state(State.ATTACKING)
		return
	var step := move_speed * delta
	var travel := dist - attack_range
	if step >= travel:
		global_position = _stop_position(to_target, dist)
		_set_state(State.ATTACKING)
	else:
		global_position += to_target.normalized() * step


func _stop_position(to_target: Vector2, dist: float) -> Vector2:
	if dist <= 0.001:
		return global_position
	return _target_position - to_target.normalized() * attack_range


func _tick_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	play_animation("attack")
	attacked.emit(attack_damage)


func _set_state(new_state: State) -> void:
	if combat_state == State.DEAD:
		return
	if combat_state == State.DYING and new_state != State.DEAD:
		return
	var previous := combat_state
	combat_state = new_state
	if new_state == State.ATTACKING and previous != State.ATTACKING and previous != State.HIT:
		attack_timer = 0.35
	state_changed.emit(state_name())


func _resume_after_hit() -> void:
	if combat_state == State.DYING or combat_state == State.DEAD:
		return
	var dist := (_target_position - global_position).length()
	if dist <= attack_range:
		_set_state(State.ATTACKING)
	else:
		_set_state(State.MOVING)


func _play_hit(amount: float, is_crit: bool) -> void:
	_spawn_floating(NumberUtil.format_int(amount), Color(1.0, 0.92, 0.45) if is_crit else Color(1, 1, 1), is_crit)
	if is_crit:
		_spawn_floating("CRITICAL!", Color(1.0, 0.55, 0.2), true)
	if combat_state != State.DYING and combat_state != State.DEAD:
		_set_state(State.HIT)
	_kill_feedback()
	if visual == null:
		_resume_after_hit()
		return
	if SettingsManager.screen_shake:
		visual.position = Vector2(randf_range(-10.0, 10.0), randf_range(-4.0, 4.0))
	visual.modulate = Color(1.2, 1.2, 1.2) if not is_crit else Color(1.4, 1.15, 0.7)
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(visual, "position", Vector2.ZERO, 0.12)
	_feedback_tween.parallel().tween_property(visual, "modulate", Color.WHITE, 0.12)
	_feedback_tween.finished.connect(_resume_after_hit, CONNECT_ONE_SHOT)


func _lunge() -> void:
	if visual == null:
		return
	_kill_feedback()
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(visual, "position:x", 22.0, 0.08)
	_feedback_tween.tween_property(visual, "position:x", 0.0, 0.12)


func _play_death() -> void:
	_spawn_floating("KO", Color(1.0, 0.78, 0.35), true)
	_kill_feedback()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	tween.parallel().tween_property(self, "scale", scale * 0.55, 0.28)
	tween.finished.connect(func() -> void:
		_set_state(State.DEAD)
		died.emit()
	)


func _spawn_floating(text: String, color: Color, big: bool) -> void:
	if not SettingsManager.damage_numbers:
		return
	var node := FLOATING_TEXT.instantiate()
	add_child(node)
	node.setup(text, color, big)


func _is_paused() -> bool:
	if GameManager.has_method("is_game_paused") and GameManager.is_game_paused():
		return true
	if GameManager.has_method("is_combat_paused") and GameManager.is_combat_paused():
		return true
	if GameManager.has_method("is_enemy_frozen") and GameManager.is_enemy_frozen():
		return true
	return false


func _kill_feedback() -> void:
	if _feedback_tween and _feedback_tween.is_valid():
		_feedback_tween.kill()
	if visual:
		visual.position = Vector2.ZERO
		visual.modulate = Color.WHITE


func _cache_nodes() -> void:
	if visual == null:
		visual = get_node_or_null("Visual")
	if body == null and visual:
		body = visual.get_node_or_null("Body")
	if name_label == null:
		name_label = $NameLabel
		hp_bar = $HPBar
		hp_label = $HPLabel


func _apply_boss_visual() -> void:
	if is_boss:
		scale = Vector2(1.4, 1.4)
		hp_bar.offset_left = -210.0
		hp_bar.offset_right = 210.0
		hp_bar.custom_minimum_size = Vector2(420, 28)
	else:
		scale = Vector2(1.0, 1.0)
		hp_bar.offset_left = -140.0
		hp_bar.offset_right = 140.0
		hp_bar.custom_minimum_size = Vector2(280, 24)


func _refresh_ui() -> void:
	name_label.text = display_name
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_label.text = "%s / %s" % [NumberUtil.format_int(current_hp), NumberUtil.format_int(max_hp)]
