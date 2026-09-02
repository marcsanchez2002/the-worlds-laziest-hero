extends Node2D

const NumberUtil := preload("res://scripts/number_util.gd")
const FLOATING_TEXT := preload("res://scenes/ui/floating_text.tscn")

const ANIM_IDLE := "idle"
const ANIM_ATTACK := "attack"
const ANIM_HIT := "hit"
const ANIM_SLEEP := "sleep"
const ANIM_LEVEL_UP := "level_up"
const ANIM_DOWN := "down"
const SPRITE_IDLE := "idle"
const SPRITE_ATTACK := "attack"
const SPRITE_DOWN := "down"
const SPRITE_WAKE_UP := "wake_up"

enum State { ACTIVE, DOWN }

signal hp_changed(current_hp: float, max_hp: float)
signal downed
signal recovered

var max_hp: float = 100.0
var current_hp: float = 100.0
var hp_regen: float = 0.0
var state: State = State.ACTIVE

var _idle_tween: Tween
var _action_tween: Tween
var _bed_level: int = 0
var _sprite_oneshot := false
@onready var visual: Node2D = $Visual
@onready var bed: Polygon2D = $Visual/Bed
@onready var sleep_label: Label = $Visual/SleepLabel
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel
@onready var hit_spark: Polygon2D = $HitSpark
@onready var animated_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
var _hit_particles: CPUParticles2D


func _ready() -> void:
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_ensure_hit_particles()
	_start_idle()
	_refresh_hp_ui()
	if hit_spark:
		hit_spark.modulate.a = 0.0


func is_down() -> bool:
	return state == State.DOWN


func setup_vitals(max_hp_value: float, regen: float) -> void:
	max_hp = maxf(1.0, roundf(max_hp_value))
	current_hp = max_hp
	hp_regen = regen
	state = State.ACTIVE
	rotation = 0.0
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	if visual:
		visual.rotation = 0.0
		visual.position = Vector2.ZERO
		visual.scale = Vector2.ONE
		visual.modulate = Color.WHITE
	_sprite_oneshot = false
	_set_sleep_text()
	_start_idle()
	_refresh_hp_ui()
	hp_changed.emit(current_hp, max_hp)


func take_damage(amount: float) -> void:
	if state == State.DOWN:
		return
	if amount <= 0.0:
		return
	var damage := maxf(1.0, roundf(amount))
	current_hp = maxf(0.0, roundf(current_hp - damage))
	play_animation(ANIM_HIT)
	_spawn_floating(NumberUtil.format_int(damage), Color(1.0, 0.45, 0.4), false)
	_flash_spark()
	_refresh_hp_ui()
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		state = State.DOWN
		play_animation(ANIM_DOWN)
		downed.emit()


func heal(amount: float) -> void:
	if state == State.DOWN or amount <= 0.0 or current_hp >= max_hp:
		return
	var previous := current_hp
	var healed := maxf(1.0, roundf(amount))
	current_hp = minf(max_hp, roundf(current_hp + healed))
	if is_equal_approx(previous, current_hp):
		return
	_refresh_hp_ui()
	hp_changed.emit(current_hp, max_hp)


func recover_from_down() -> void:
	state = State.ACTIVE
	current_hp = max_hp
	_set_sleep_text()
	_play_wake()
	_spawn_floating("+ FULL HP", Color(0.55, 0.95, 0.62), true)
	_refresh_hp_ui()
	hp_changed.emit(current_hp, max_hp)
	recovered.emit()


func apply_bed_tier(level: int, color: Color) -> void:
	_bed_level = level
	if bed:
		bed.color = color
	scale = Vector2.ONE * (1.0 + float(level) * 0.04)
	_set_sleep_text()


func play_animation(anim_name: String) -> void:
	match anim_name:
		ANIM_ATTACK:
			_nudge_attack()
			_flash(Color(1.0, 0.92, 0.62))
			_play_sprite(SPRITE_ATTACK, true)
		ANIM_HIT:
			_shake()
			_flash(Color(1.0, 0.45, 0.4))
			_play_hit_impact()
		ANIM_LEVEL_UP:
			_flash(Color(1.0, 0.86, 0.35))
		ANIM_DOWN:
			_play_down()
		ANIM_IDLE, ANIM_SLEEP:
			if state != State.DOWN:
				_start_idle()
				modulate = Color.WHITE
		_:
			if state != State.DOWN:
				modulate = Color.WHITE


func _start_idle() -> void:
	if visual == null or state == State.DOWN:
		return
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	visual.scale = Vector2.ONE
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(visual, "scale", Vector2(1.015, 0.985), 1.15)
	_idle_tween.tween_property(visual, "scale", Vector2.ONE, 1.15)
	if not _sprite_oneshot:
		_play_sprite(SPRITE_IDLE, false)


func _nudge_attack() -> void:
	if visual == null or state == State.DOWN:
		return
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween()
	_action_tween.tween_property(visual, "position:x", -18.0, 0.04)
	_action_tween.tween_property(visual, "position:x", 0.0, 0.10)


func _shake() -> void:
	if visual == null:
		return
	if not SettingsManager.screen_shake:
		return
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	visual.position = Vector2(randf_range(-8.0, 8.0), randf_range(-4.0, 4.0))
	_action_tween = create_tween()
	_action_tween.tween_property(visual, "position", Vector2.ZERO, 0.14)


func _play_down() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	if sleep_label:
		sleep_label.text = "💤"
	if visual:
		visual.scale = Vector2.ONE
		_action_tween = create_tween()
		_action_tween.tween_property(visual, "rotation", 0.18, 0.22)
		_action_tween.parallel().tween_property(visual, "position", Vector2(12.0, 10.0), 0.22)
		_action_tween.parallel().tween_property(visual, "scale", Vector2(0.92, 0.92), 0.22)
	_play_sprite(SPRITE_DOWN, false)


func _play_wake() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_play_sprite(SPRITE_WAKE_UP, true)
	if visual == null:
		_start_idle()
		return
	_action_tween = create_tween()
	_action_tween.tween_property(visual, "rotation", 0.0, 0.18)
	_action_tween.parallel().tween_property(visual, "position", Vector2.ZERO, 0.18)
	_action_tween.parallel().tween_property(visual, "scale", Vector2(1.06, 1.06), 0.12)
	_action_tween.tween_property(visual, "scale", Vector2.ONE, 0.12)
	_action_tween.finished.connect(_start_idle, CONNECT_ONE_SHOT)


func _play_sprite(anim: String, oneshot: bool) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(anim):
		return
	_sprite_oneshot = oneshot
	animated_sprite.play(anim)


func _on_sprite_animation_finished() -> void:
	if animated_sprite == null:
		return
	var finished := String(animated_sprite.animation)
	_sprite_oneshot = false
	if state == State.DOWN:
		if finished != SPRITE_DOWN:
			_play_sprite(SPRITE_DOWN, false)
		return
	if finished == SPRITE_ATTACK or finished == SPRITE_WAKE_UP:
		_play_sprite(SPRITE_IDLE, false)


func _set_sleep_text() -> void:
	if sleep_label == null:
		return
	if state == State.DOWN:
		sleep_label.text = "💤"
		return
	sleep_label.text = "ZZZ" if _bed_level < 4 else "Zzz..+"


func _flash(tint: Color) -> void:
	if visual == null:
		return
	visual.modulate = tint
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.22)


func _flash_spark() -> void:
	if hit_spark == null:
		return
	hit_spark.modulate = Color(1.0, 0.35, 0.28, 0.9)
	var tween := create_tween()
	tween.tween_property(hit_spark, "modulate:a", 0.0, 0.22)


func _ensure_hit_particles() -> void:
	if _hit_particles != null and is_instance_valid(_hit_particles):
		return
	_hit_particles = CPUParticles2D.new()
	_hit_particles.name = "HitParticles"
	_hit_particles.position = Vector2(0, -40)
	_hit_particles.z_index = 8
	_hit_particles.emitting = false
	_hit_particles.one_shot = true
	_hit_particles.explosiveness = 1.0
	_hit_particles.amount = 12
	_hit_particles.lifetime = 0.32
	_hit_particles.local_coords = true
	_hit_particles.texture = _make_impact_texture()
	_hit_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_hit_particles.emission_sphere_radius = 36.0
	_hit_particles.direction = Vector2(0, -1)
	_hit_particles.spread = 180.0
	_hit_particles.initial_velocity_min = 70.0
	_hit_particles.initial_velocity_max = 150.0
	_hit_particles.gravity = Vector2(0, 240)
	_hit_particles.scale_amount_min = 0.45
	_hit_particles.scale_amount_max = 0.9
	_hit_particles.color = Color(1.0, 0.88, 0.42, 1.0)
	var fade := Gradient.new()
	fade.colors = PackedColorArray([
		Color(1.0, 0.95, 0.55, 1.0),
		Color(1.0, 0.55, 0.28, 0.85),
		Color(1.0, 0.35, 0.22, 0.0),
	])
	_hit_particles.color_ramp = fade
	add_child(_hit_particles)


func _make_impact_texture() -> Texture2D:
	var size := 16
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2((size - 1) * 0.5, (size - 1) * 0.5)
	for y in size:
		for x in size:
			var point := Vector2(x, y) - center
			var ax := absf(point.x)
			var ay := absf(point.y)
			var on_cross := (ax <= 1.25 and ay <= 6.5) or (ay <= 1.25 and ax <= 6.5)
			var on_diag := absf(ax - ay) <= 1.2 and ax <= 5.0
			if on_cross or on_diag:
				var falloff := clampf(point.length() / 8.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 1.0, 0.78, 1.0 - falloff * 0.2))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _play_hit_impact() -> void:
	_ensure_hit_particles()
	if _hit_particles == null:
		return
	_hit_particles.restart()


func _spawn_floating(text: String, color: Color, big: bool) -> void:
	if not SettingsManager.damage_numbers:
		return
	var node := FLOATING_TEXT.instantiate()
	add_child(node)
	node.setup(text, color, big)


func _refresh_hp_ui() -> void:
	if hp_bar == null:
		hp_bar = get_node_or_null("HPBar")
		hp_label = get_node_or_null("HPLabel")
	if hp_bar == null:
		return
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	if hp_label:
		hp_label.text = "%s / %s" % [NumberUtil.format_int(current_hp), NumberUtil.format_int(max_hp)]
