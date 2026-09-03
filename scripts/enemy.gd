extends Node2D

const NumberUtil := preload("res://scripts/number_util.gd")
const FLOATING_TEXT := preload("res://scenes/ui/floating_text.tscn")

enum State { MOVING, ATTACKING, HIT, DYING, DEAD }

const GOBLIN_IMPACT_FRAME := 5

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
var _is_slime: bool = false
var _is_goblin: bool = false
var _goblin_oneshot: bool = false
var _goblin_anim_connected: bool = false
var _goblin_hit_pending: bool = false
var _slime_time: float = 0.0
var _slime_lock: bool = false
var _slime_tween: Tween

@onready var visual: Node2D = $Visual
@onready var deform: Node2D = $Visual/Deform
@onready var body: Polygon2D = $Visual/Deform/Body
@onready var sprite: Sprite2D = $Visual/Deform/Sprite
@onready var animated_sprite: AnimatedSprite2D = $Visual/Deform/AnimatedSprite2D
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
	_is_slime = String(definition.get("id", "")) == "slime"
	_is_goblin = String(definition.get("id", "")) == "goblin"
	_goblin_oneshot = false
	_goblin_hit_pending = false
	_slime_time = randf() * 8.0
	_slime_lock = false
	_kill_slime_tween()
	_reset_slime_deform()
	_apply_visual(definition)
	_apply_boss_visual()
	_refresh_ui()
	_set_state(State.MOVING)
	if _is_goblin:
		_play_goblin_sprite("idle", false)


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
	if not _is_goblin_mid_swing():
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
			if _is_goblin:
				_play_goblin_sprite("hurt", true)
		"death":
			if _is_goblin:
				_play_goblin_sprite("death", true)
		_:
			pass


func _process(delta: float) -> void:
	if combat_state == State.DEAD:
		return
	if combat_state != State.DYING and not _is_paused():
		match combat_state:
			State.MOVING:
				_move_towards(delta)
			State.ATTACKING:
				_tick_attack(delta)
			State.HIT:
				pass
		_update_slime_visual(delta)
	if _is_slime:
		_anchor_slime_to_ground()


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
	if not _is_goblin:
		attacked.emit(attack_damage)


func _set_state(new_state: State) -> void:
	if combat_state == State.DEAD:
		return
	if combat_state == State.DYING and new_state != State.DEAD:
		return
	var previous := combat_state
	combat_state = new_state
	if new_state == State.ATTACKING and previous != State.ATTACKING and previous != State.HIT:
		attack_timer = 0.0 if _is_goblin else 0.35
	state_changed.emit(state_name())
	_sync_goblin_loop_anim()


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
	if _is_goblin_mid_swing():
		_pause_goblin_swing_briefly(is_crit)
		return
	if combat_state != State.DYING and combat_state != State.DEAD:
		_set_state(State.HIT)
	_kill_feedback()
	if visual == null:
		_resume_after_hit()
		return
	if SettingsManager.screen_shake:
		if _is_slime:
			visual.position = Vector2(randf_range(-10.0, 10.0), 0.0)
		else:
			visual.position = Vector2(randf_range(-10.0, 10.0), randf_range(-4.0, 4.0))
	visual.modulate = Color(1.2, 1.2, 1.2) if not is_crit else Color(1.4, 1.15, 0.7)
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(visual, "position", Vector2.ZERO, 0.12)
	_feedback_tween.parallel().tween_property(visual, "modulate", Color.WHITE, 0.12)
	_feedback_tween.finished.connect(_resume_after_hit, CONNECT_ONE_SHOT)


func _lunge() -> void:
	if visual == null:
		return
	if _is_slime:
		_play_slime_attack()
		return
	if _is_goblin:
		_play_goblin_sprite("attack", true)
		return
	_kill_feedback()
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(visual, "position:x", 22.0, 0.08)
	_feedback_tween.tween_property(visual, "position:x", 0.0, 0.12)


func _play_death() -> void:
	_spawn_floating("KO", Color(1.0, 0.78, 0.35), true)
	_kill_feedback()
	if _is_slime:
		_play_slime_death()
		return
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
	if deform == null and visual:
		deform = visual.get_node_or_null("Deform")
	var deform_root: Node = deform if deform else visual
	if body == null and deform_root:
		body = deform_root.get_node_or_null("Body")
	if sprite == null and deform_root:
		sprite = deform_root.get_node_or_null("Sprite")
	if animated_sprite == null and deform_root:
		animated_sprite = deform_root.get_node_or_null("AnimatedSprite2D")
	if name_label == null:
		name_label = $NameLabel
		hp_bar = $HPBar
		hp_label = $HPLabel


func _apply_visual(definition: Dictionary) -> void:
	if _is_goblin:
		if animated_sprite:
			animated_sprite.visible = true
			_ensure_goblin_anim_connected()
		if sprite:
			sprite.visible = false
			sprite.texture = null
		if body:
			body.visible = false
		return
	if animated_sprite:
		animated_sprite.visible = false
		animated_sprite.stop()
	var tex_path := String(definition.get("texture", ""))
	var has_sprite := tex_path != "" and ResourceLoader.exists(tex_path)
	if has_sprite and sprite:
		sprite.texture = load(tex_path)
		sprite.visible = true
		if body:
			body.visible = false
		return
	if sprite:
		sprite.visible = false
		sprite.texture = null
	if body:
		body.visible = true
		body.color = definition.get("color", Color(0.7, 0.7, 0.7))


func _ensure_goblin_anim_connected() -> void:
	if _goblin_anim_connected or animated_sprite == null:
		return
	animated_sprite.animation_finished.connect(_on_goblin_animation_finished)
	animated_sprite.frame_changed.connect(_on_goblin_frame_changed)
	_goblin_anim_connected = true


func _is_goblin_mid_swing() -> bool:
	if not _is_goblin or not _goblin_oneshot or animated_sprite == null:
		return false
	return String(animated_sprite.animation) == "attack"


func _play_goblin_sprite(anim: String, oneshot: bool) -> void:
	if not _is_goblin or animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(anim):
		return
	if anim != "attack":
		_goblin_hit_pending = false
	_goblin_oneshot = oneshot
	animated_sprite.stop()
	animated_sprite.play(anim)
	if anim == "attack":
		_goblin_hit_pending = true


func _resolve_goblin_swing_hit() -> void:
	if not _goblin_hit_pending:
		return
	_goblin_hit_pending = false
	if combat_state == State.DYING or combat_state == State.DEAD:
		return
	if _is_paused():
		return
	attacked.emit(attack_damage)


func _pause_goblin_swing_briefly(is_crit: bool) -> void:
	if animated_sprite:
		animated_sprite.pause()
	_kill_feedback()
	if visual == null:
		return
	if SettingsManager.screen_shake:
		visual.position = Vector2(randf_range(-10.0, 10.0), randf_range(-4.0, 4.0))
	visual.modulate = Color(1.2, 1.2, 1.2) if not is_crit else Color(1.4, 1.15, 0.7)
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(visual, "position", Vector2.ZERO, 0.12)
	_feedback_tween.parallel().tween_property(visual, "modulate", Color.WHITE, 0.12)
	_feedback_tween.finished.connect(_resume_goblin_swing, CONNECT_ONE_SHOT)


func _resume_goblin_swing() -> void:
	if combat_state == State.DYING or combat_state == State.DEAD:
		return
	if animated_sprite == null or String(animated_sprite.animation) != "attack":
		return
	if not _goblin_oneshot:
		return
	var frame := animated_sprite.frame
	var progress := animated_sprite.frame_progress
	animated_sprite.play(&"attack")
	animated_sprite.set_frame_and_progress(frame, progress)


func _on_goblin_frame_changed() -> void:
	if not _is_goblin or animated_sprite == null:
		return
	if String(animated_sprite.animation) != "attack":
		return
	if animated_sprite.frame == GOBLIN_IMPACT_FRAME:
		_resolve_goblin_swing_hit()


func _hold_goblin_attack_pose() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation("attack"):
		return
	_goblin_oneshot = false
	animated_sprite.animation = &"attack"
	var last := animated_sprite.sprite_frames.get_frame_count("attack") - 1
	animated_sprite.frame = maxi(last, 0)
	animated_sprite.pause()


func _sync_goblin_loop_anim() -> void:
	if not _is_goblin or _goblin_oneshot:
		return
	match combat_state:
		State.MOVING:
			_play_goblin_sprite("move", false)
		State.ATTACKING:
			var current := String(animated_sprite.animation) if animated_sprite else ""
			if current == "attack" or current == "hurt":
				_hold_goblin_attack_pose()
		_:
			pass


func _on_goblin_animation_finished() -> void:
	if not _is_goblin or animated_sprite == null:
		return
	var finished := String(animated_sprite.animation)
	if finished == "death":
		_goblin_hit_pending = false
		return
	if finished == "attack" or finished == "hurt":
		_goblin_oneshot = false
		if combat_state == State.ATTACKING:
			_hold_goblin_attack_pose()
		else:
			_sync_goblin_loop_anim()


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


func _update_slime_visual(delta: float) -> void:
	if not _is_slime or deform == null or _slime_lock:
		return
	_slime_time += delta
	if combat_state == State.MOVING:
		_apply_slime_crawl()
	else:
		_apply_slime_idle()


func _apply_slime_idle() -> void:
	var breathe := 0.5 + 0.5 * sin(_slime_time * TAU / 2.6)
	var ripple := sin(_slime_time * TAU / 1.15)
	var wave := sin(_slime_time * TAU / 1.7)
	var sx := 1.0 + breathe * 0.07 + ripple * 0.012
	var sy := 1.0 - breathe * 0.05
	_set_slime_deform(Vector2(sx, sy), 0.0, wave * 0.045)


func _apply_slime_crawl() -> void:
	var facing := _slime_facing()
	var t := fposmod(_slime_time, 0.92) / 0.92
	var sx: float
	var sy: float
	var ox: float
	var sk: float
	if t < 0.33:
		var u := _slime_smooth(t / 0.33)
		sx = lerpf(1.0, 0.90, u)
		sy = 1.0
		ox = lerpf(0.0, facing * -4.0, u)
		sk = lerpf(0.0, facing * -0.05, u)
	elif t < 0.66:
		var u := _slime_smooth((t - 0.33) / 0.33)
		sx = lerpf(0.90, 1.14, u)
		sy = lerpf(1.0, 0.96, u)
		ox = lerpf(facing * -4.0, facing * 9.0, u)
		sk = lerpf(facing * -0.05, facing * 0.10, u)
	else:
		var u := _slime_smooth((t - 0.66) / 0.34)
		sx = lerpf(1.14, 1.0, u)
		sy = lerpf(0.96, 1.0, u)
		ox = lerpf(facing * 9.0, 0.0, u)
		sk = lerpf(facing * 0.10, 0.0, u)
	sk += sin(_slime_time * 6.0) * 0.02
	_set_slime_deform(Vector2(sx, sy), ox, sk)


func _play_slime_attack() -> void:
	if deform == null:
		return
	_kill_feedback()
	_kill_slime_tween()
	_slime_lock = true
	var facing := _slime_facing()
	_slime_tween = create_tween()
	_slime_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_slime_tween.tween_property(deform, "scale", Vector2(0.86, 1.0), 0.05)
	_slime_tween.parallel().tween_property(deform, "position:x", facing * -8.0, 0.05)
	_slime_tween.parallel().tween_property(deform, "skew", facing * -0.08, 0.05)
	_slime_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_slime_tween.tween_property(deform, "scale", Vector2(1.24, 0.92), 0.07)
	_slime_tween.parallel().tween_property(deform, "position:x", facing * 16.0, 0.07)
	_slime_tween.parallel().tween_property(deform, "skew", facing * 0.16, 0.07)
	_slime_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_slime_tween.tween_property(deform, "scale", Vector2.ONE, 0.12)
	_slime_tween.parallel().tween_property(deform, "position:x", 0.0, 0.12)
	_slime_tween.parallel().tween_property(deform, "skew", 0.0, 0.12)
	_slime_tween.finished.connect(func() -> void:
		_slime_lock = false
	, CONNECT_ONE_SHOT)


func _play_slime_death() -> void:
	_kill_slime_tween()
	_slime_lock = true
	if deform == null:
		_set_state(State.DEAD)
		died.emit()
		return
	deform.position.x = 0.0
	deform.skew = 0.0
	_slime_tween = create_tween()
	_slime_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_slime_tween.tween_property(deform, "scale", Vector2(1.36, 0.18), 0.42)
	_slime_tween.tween_property(self, "modulate:a", 0.0, 0.32)
	_slime_tween.finished.connect(func() -> void:
		_set_state(State.DEAD)
		died.emit()
	, CONNECT_ONE_SHOT)


func _set_slime_deform(body_scale: Vector2, offset_x: float, body_skew: float) -> void:
	if deform == null:
		return
	deform.scale = body_scale
	deform.skew = body_skew
	deform.position.x = offset_x


func _anchor_slime_to_ground() -> void:
	if deform == null:
		return
	deform.position.y = _slime_foot_y() * (1.0 - deform.scale.y)


func _slime_foot_y() -> float:
	if sprite and sprite.visible and sprite.texture:
		return sprite.position.y + sprite.texture.get_height() * absf(sprite.scale.y) * 0.5
	if body:
		var max_y := 0.0
		for point in body.polygon:
			max_y = maxf(max_y, point.y)
		return max_y
	return 80.0


func _slime_facing() -> float:
	return -1.0 if (_target_position.x - global_position.x) < 0.0 else 1.0


func _slime_smooth(value: float) -> float:
	var u := clampf(value, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


func _reset_slime_deform() -> void:
	if deform == null:
		return
	deform.scale = Vector2.ONE
	deform.skew = 0.0
	deform.position = Vector2.ZERO


func _kill_slime_tween() -> void:
	if _slime_tween and _slime_tween.is_valid():
		_slime_tween.kill()
	_slime_tween = null
