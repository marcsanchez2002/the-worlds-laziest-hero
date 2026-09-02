extends CanvasLayer

const GameInfo := preload("res://scripts/app_info.gd")
const NumberUtil := preload("res://scripts/number_util.gd")

@onready var overlay_root: Control = %OverlayRoot
@onready var dimmer: ColorRect = %Dimmer
@onready var panel: PanelContainer = %Panel
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var pause_button: Button = %PauseButton
@onready var stage_label: Label = %StageLabel
@onready var gold_label: Label = %GoldLabel
@onready var enemy_label: Label = %EnemyLabel
@onready var settings_overlay = %SettingsOverlay
@onready var dialog = %MenuDialog

var _open: bool = false
var _animating: bool = false
var _leaving: bool = false
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay_root.visible = false
	overlay_root.modulate.a = 0.0
	settings_overlay.visible = false
	pause_button.pressed.connect(_on_pause_button_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	settings_overlay.closed.connect(_on_settings_closed)
	panel.resized.connect(_update_panel_pivot)
	_update_panel_pivot()


func _input(event: InputEvent) -> void:
	if _leaving or _animating or SceneTransition.is_busy():
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	if dialog.is_open():
		return
	if settings_overlay.visible:
		return
	get_viewport().set_input_as_handled()
	if _open:
		_close()
	else:
		_open_menu()


func _on_pause_button_pressed() -> void:
	if _leaving or _animating or SceneTransition.is_busy() or dialog.is_open():
		return
	if settings_overlay.visible:
		return
	if _open:
		_close()
	else:
		_open_menu()


func _on_resume_pressed() -> void:
	_close()


func _on_settings_pressed() -> void:
	if not _open or _animating or dialog.is_open() or _leaving:
		return
	overlay_root.visible = false
	settings_overlay.show_as_overlay()


func _on_settings_closed() -> void:
	if _leaving:
		return
	overlay_root.visible = true
	overlay_root.modulate.a = 1.0
	_refresh_status()
	resume_button.grab_focus()


func _on_main_menu_pressed() -> void:
	if not _open or _animating or _leaving:
		return
	dialog.present("RETURN TO MAIN MENU?", "Your progress is saved automatically.", "CANCEL", "MAIN MENU")
	var result: Variant = await dialog.finished
	if result != true:
		resume_button.grab_focus()
		return
	_leave_to_menu()


func _open_menu() -> void:
	if _open or _animating or _leaving:
		return
	_open = true
	_animating = true
	GameManager.set_game_paused(true)
	_refresh_status()
	overlay_root.visible = true
	overlay_root.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	_update_panel_pivot()
	_play_sfx("pause_open")
	resume_button.grab_focus()
	_kill_tween()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true)
	_tween.tween_property(overlay_root, "modulate:a", 1.0, 0.2)
	_tween.tween_property(panel, "scale", Vector2.ONE, 0.2)
	await _tween.finished
	_animating = false


func _close() -> void:
	if not _open or _animating or _leaving or settings_overlay.visible:
		return
	_animating = true
	_play_sfx("pause_close")
	_kill_tween()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true)
	_tween.tween_property(overlay_root, "modulate:a", 0.0, 0.18)
	_tween.tween_property(panel, "scale", Vector2(0.96, 0.96), 0.18)
	await _tween.finished
	overlay_root.visible = false
	GameManager.set_game_paused(false)
	_open = false
	_animating = false


func _leave_to_menu() -> void:
	_leaving = true
	GameManager.end_session()
	SceneTransition.change_scene(GameInfo.MENU_SCENE)


func _refresh_status() -> void:
	stage_label.text = "STAGE %s" % str(GameManager.stage)
	gold_label.text = "GOLD  %s" % NumberUtil.format_int(GameManager.gold)
	var enemy: Node = GameManager.current_enemy
	if enemy and is_instance_valid(enemy):
		var enemy_name := String(enemy.display_name)
		var current_hp := NumberUtil.format_int(float(enemy.current_hp))
		var max_hp := NumberUtil.format_int(float(enemy.max_hp))
		enemy_label.text = "ENEMY  %s\n%s / %s HP" % [enemy_name, current_hp, max_hp]
	else:
		enemy_label.text = "ENEMY  —"


func _update_panel_pivot() -> void:
	if panel:
		panel.pivot_offset = panel.size * 0.5


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _play_sfx(id: String) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play"):
		audio.play(id)
