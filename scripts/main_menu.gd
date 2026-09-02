extends Control

# TitleLine1 / TitleLine2 keep theme_override_font_sizes so a custom font can be assigned later.
const GameInfo := preload("res://scripts/app_info.gd")

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var no_save_label: Label = %NoSaveLabel
@onready var version_label: Label = %VersionLabel
@onready var dialog = %MenuDialog

var _busy: bool = false


func _ready() -> void:
	version_label.text = GameInfo.VERSION
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_refresh_continue()
	if continue_button.disabled:
		new_game_button.grab_focus()
	else:
		continue_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _busy or dialog.is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
		get_viewport().set_input_as_handled()


func _refresh_continue() -> void:
	var has_save := GameManager.has_save()
	continue_button.disabled = not has_save
	no_save_label.visible = not has_save


func _on_continue_pressed() -> void:
	if _busy or continue_button.disabled or not GameManager.has_save():
		return
	_busy = true
	GameManager.load_game()
	SceneTransition.change_scene(GameInfo.GAME_SCENE)


func _on_new_game_pressed() -> void:
	if _busy:
		return
	if GameManager.has_save():
		dialog.present("START A NEW GAME?", "Your current progress will be deleted.", "CANCEL", "NEW GAME")
		var result: Variant = await dialog.finished
		if result != true:
			return
	_start_new_game()


func _on_settings_pressed() -> void:
	if _busy:
		return
	_busy = true
	SceneTransition.change_scene(GameInfo.SETTINGS_SCENE)


func _on_quit_pressed() -> void:
	if _busy:
		return
	dialog.present("QUIT GAME?", "Are you sure you want to leave?", "CANCEL", "QUIT")
	var result: Variant = await dialog.finished
	if result != true:
		return
	_quit_game()


func _start_new_game() -> void:
	_busy = true
	GameManager.new_game()
	SceneTransition.change_scene(GameInfo.GAME_SCENE)


func _quit_game() -> void:
	if OS.has_feature("web"):
		return
	get_tree().quit()
