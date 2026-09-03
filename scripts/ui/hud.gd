extends Control

const NumberUtil := preload("res://scripts/number_util.gd")
const SkillCatalog := preload("res://data/skill_catalog.gd")

@onready var gold_label: Label = %GoldLabel
@onready var stage_label: Label = %StageLabel
@onready var damage_label: Label = %DamageLabel
@onready var kills_label: Label = %KillsLabel
@onready var attack_button: Button = %AttackButton
@onready var lazy_power_label: Label = %LazyPowerLabel
@onready var combo_label: Label = %ComboLabel
@onready var comfort_bar: ProgressBar = %ComfortBar
@onready var comfort_label: Label = %ComfortLabel
@onready var tabs: TabContainer = %SideDock

var _flash: ColorRect
var _announce: Label
var _event_panel: PanelContainer
var _event_title: Label
var _event_body: Label
var _gold_float: Label
var _recovery_panel: PanelContainer
var _recovery_title: Label
var _recovery_subtitle: Label
var _recovery_count: Label
var _recovery_phase: String = ""
var _attack_ready: bool = true
var _recovery_hide_tween: Tween


func _ready() -> void:
	_build_overlays()
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.stage_changed.connect(_on_stage_changed)
	GameManager.stats_changed.connect(_refresh_stats)
	GameManager.attack_ready_changed.connect(_on_attack_ready_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.comfort_changed.connect(_on_comfort_changed)
	GameManager.hit_landed.connect(_on_hit_landed)
	GameManager.announcement.connect(_on_announcement)
	GameManager.gold_popup.connect(_on_gold_popup)
	GameManager.event_offered.connect(_on_event_offered)
	GameManager.event_cleared.connect(_on_event_cleared)
	GameManager.achievement_unlocked.connect(_on_achievement)
	GameManager.combat_paused_changed.connect(_on_combat_paused_changed)
	attack_button.pressed.connect(_on_attack_pressed)
	%SaveButton.pressed.connect(_on_save_pressed)
	%LoadButton.pressed.connect(_on_load_pressed)
	_refresh_all()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var key: int = key_event.keycode
	if key == KEY_SPACE:
		if GameManager.is_game_paused() or GameManager.is_combat_paused():
			get_viewport().set_input_as_handled()
			return
		GameManager.try_manual_attack()
		get_viewport().set_input_as_handled()
	elif key >= KEY_1 and key <= KEY_8:
		tabs.select_tab_index(key - KEY_1)
		get_viewport().set_input_as_handled()
	else:
		for skill in SkillCatalog.all():
			if key == int(skill.get("key", KEY_NONE)):
				if not GameManager.is_game_paused() and not GameManager.is_combat_paused():
					GameManager.try_skill(String(skill["id"]))
				get_viewport().set_input_as_handled()
				break


func _process(_delta: float) -> void:
	if _recovery_phase != "countdown":
		return
	_update_recovery_count()


func _on_attack_pressed() -> void:
	if GameManager.is_game_paused() or GameManager.is_combat_paused():
		return
	GameManager.try_manual_attack()


func _on_save_pressed() -> void:
	GameManager.save_game()
	_on_announcement("SAVED")


func _on_load_pressed() -> void:
	GameManager.load_game()
	_on_announcement("LOADED")


func _on_gold_changed(_new_gold: float) -> void:
	_refresh_gold()


func _on_stage_changed(_new_stage: int) -> void:
	_refresh_stage()


func _on_attack_ready_changed(is_ready: bool) -> void:
	_attack_ready = is_ready
	_sync_attack_button()


func _on_combat_paused_changed(is_paused: bool) -> void:
	_sync_attack_button()
	if is_paused:
		_flash_screen(Color(0.85, 0.12, 0.12, 0.34))
		_show_recovery_countdown()
	elif _recovery_phase == "countdown":
		_show_recovery_done()
	else:
		_hide_recovery()


func _on_combo_changed(combo_count: int) -> void:
	if combo_count <= 1:
		combo_label.text = ""
	else:
		combo_label.text = "Lazy Combo x%s" % str(combo_count)


func _on_comfort_changed(current: float, maximum: float) -> void:
	comfort_bar.max_value = maximum
	comfort_bar.value = current
	comfort_label.text = "Comfort %s / %s" % [NumberUtil.format(current), NumberUtil.format(maximum)]


func _on_hit_landed(_amount: float, is_crit: bool, _is_magic: bool) -> void:
	if is_crit:
		_flash_screen(Color(1.0, 0.82, 0.35, 0.28))


func _on_announcement(text: String) -> void:
	_announce.text = text
	_announce.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(_announce, "modulate:a", 0.0, 0.45)


func _on_gold_popup(amount: float) -> void:
	_gold_float.text = "+%s Gold" % NumberUtil.format_int(amount)
	_gold_float.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.7)
	tween.tween_property(_gold_float, "modulate:a", 0.0, 0.4)


func _on_event_offered(event: Dictionary) -> void:
	_event_title.text = String(event.get("name", "Event"))
	_event_body.text = String(event.get("description", ""))
	_event_panel.visible = true


func _on_event_cleared() -> void:
	_event_panel.visible = false


func _on_achievement(_id: String) -> void:
	_on_announcement("ACHIEVEMENT")


func _refresh_all() -> void:
	_refresh_gold()
	_refresh_stage()
	_refresh_stats()
	_attack_ready = true
	_on_combo_changed(GameManager.combo_count)
	_on_comfort_changed(GameManager.hero_comfort, GameManager.BALANCE.hero_max_comfort)
	_on_combat_paused_changed(GameManager.is_combat_paused())


func _refresh_gold() -> void:
	gold_label.text = "Gold: %s" % NumberUtil.format_int(GameManager.gold)


func _refresh_stage() -> void:
	var world: Dictionary = GameManager.get_world()
	stage_label.text = "W%s %s  |  Stage %s" % [str(world.get("id", 1)), String(world.get("name", "")), NumberUtil.format(float(GameManager.stage))]


func _refresh_stats() -> void:
	damage_label.text = "Damage: %s" % NumberUtil.format_int(GameManager.get_hero_base_damage())
	kills_label.text = "Kills: %s" % NumberUtil.format(GameManager.total_kills)
	lazy_power_label.text = "Lazy Power: %s" % NumberUtil.format_mult(GameManager.get_lazy_power())


func _flash_screen(color: Color) -> void:
	if not SettingsManager.screen_shake:
		return
	_flash.color = color
	_flash.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_flash, "modulate:a", 0.0, 0.18)


func _build_overlays() -> void:
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_flash.modulate.a = 0.0
	add_child(_flash)

	_announce = Label.new()
	_announce.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_announce.offset_left = -400.0
	_announce.offset_right = 400.0
	_announce.offset_top = 160.0
	_announce.offset_bottom = 230.0
	_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce.add_theme_font_size_override("font_size", 42)
	_announce.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	_announce.modulate.a = 0.0
	_announce.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_announce)

	_gold_float = Label.new()
	_gold_float.set_anchors_preset(Control.PRESET_CENTER)
	_gold_float.offset_left = -200.0
	_gold_float.offset_right = 200.0
	_gold_float.offset_top = -40.0
	_gold_float.offset_bottom = 10.0
	_gold_float.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_float.add_theme_font_size_override("font_size", 28)
	_gold_float.add_theme_color_override("font_color", Color(0.98, 0.86, 0.38))
	_gold_float.modulate.a = 0.0
	_gold_float.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gold_float)

	_event_panel = _make_popup_panel(Vector2(520, 240))
	_event_panel.offset_left = -260.0
	_event_panel.offset_right = 260.0
	_event_panel.offset_top = 150.0
	_event_panel.offset_bottom = 400.0
	var event_list := _event_panel.get_node("Box") as VBoxContainer
	_event_title = _popup_label(event_list, "Event", 24)
	_event_body = _popup_label(event_list, "", 16)
	var event_row := HBoxContainer.new()
	event_row.add_theme_constant_override("separation", 12)
	event_list.add_child(event_row)
	var accept := Button.new()
	accept.text = "ACCEPT"
	accept.custom_minimum_size = Vector2(0, 44)
	accept.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accept.pressed.connect(GameManager.accept_event)
	event_row.add_child(accept)
	var ignore := Button.new()
	ignore.text = "IGNORE"
	ignore.custom_minimum_size = Vector2(0, 44)
	ignore.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ignore.pressed.connect(GameManager.ignore_event)
	event_row.add_child(ignore)
	_event_panel.visible = false

	_build_recovery_overlay()
	if tabs:
		tabs.move_to_front()
	if attack_button:
		attack_button.move_to_front()


func _build_recovery_overlay() -> void:
	_recovery_panel = PanelContainer.new()
	_recovery_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_recovery_panel.offset_left = 220.0
	_recovery_panel.offset_top = 340.0
	_recovery_panel.offset_right = 1420.0
	_recovery_panel.offset_bottom = 720.0
	_recovery_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_recovery_panel.z_index = 5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.1, 0.78)
	style.border_color = Color(0.91, 0.76, 0.42, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	_recovery_panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	_recovery_panel.add_child(box)
	_recovery_title = _popup_label(box, "TOO LAZY TO DIE...", 36)
	_recovery_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	_recovery_subtitle = _popup_label(box, "Recovering...", 22)
	_recovery_count = _popup_label(box, "3", 72)
	_recovery_count.add_theme_color_override("font_color", Color(0.98, 0.9, 0.55))
	add_child(_recovery_panel)
	_recovery_panel.visible = false


func _sync_attack_button() -> void:
	attack_button.disabled = not _attack_ready or GameManager.is_combat_paused()


func _show_recovery_countdown() -> void:
	if _recovery_panel == null:
		return
	if _recovery_hide_tween and _recovery_hide_tween.is_valid():
		_recovery_hide_tween.kill()
	_recovery_phase = "countdown"
	_recovery_title.text = "TOO LAZY TO DIE..."
	_recovery_subtitle.text = "Recovering..."
	_recovery_panel.visible = true
	_update_recovery_count()


func _update_recovery_count() -> void:
	if _recovery_count == null:
		return
	var left := 0.0
	if GameManager.has_method("get_recovery_time_left"):
		left = GameManager.get_recovery_time_left()
	_recovery_count.text = str(maxi(1, ceili(left)))


func _show_recovery_done() -> void:
	if _recovery_panel == null:
		return
	_recovery_phase = "done"
	_recovery_title.text = "RETURNING TO STAGE %s" % str(GameManager.stage)
	_recovery_subtitle.text = "+ FULL HP"
	_recovery_count.text = ""
	_recovery_panel.visible = true
	if _recovery_hide_tween and _recovery_hide_tween.is_valid():
		_recovery_hide_tween.kill()
	_recovery_hide_tween = create_tween()
	_recovery_hide_tween.tween_interval(0.55)
	_recovery_hide_tween.tween_callback(_hide_recovery)


func _hide_recovery() -> void:
	_recovery_phase = ""
	if _recovery_panel:
		_recovery_panel.visible = false


func _make_popup_panel(size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.1, 0.14, 0.96)
	style.border_color = Color(0.91, 0.76, 0.42, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	add_child(panel)
	return panel


func _popup_label(parent: Control, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82))
	parent.add_child(label)
	return label
