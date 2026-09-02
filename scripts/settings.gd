extends Control

signal closed

const GameInfo := preload("res://scripts/app_info.gd")

@onready var gameplay_cat: Button = %GameplayCat
@onready var audio_cat: Button = %AudioCat
@onready var video_cat: Button = %VideoCat
@onready var gameplay_page: Control = %GameplayPage
@onready var audio_page: Control = %AudioPage
@onready var video_page: Control = %VideoPage
@onready var damage_numbers_button: Button = %DamageNumbersButton
@onready var screen_shake_button: Button = %ScreenShakeButton
@onready var auto_advance_button: Button = %AutoAdvanceButton
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SfxValue
@onready var mute_all_button: Button = %MuteAllButton
@onready var fullscreen_button: Button = %FullscreenButton
@onready var vsync_button: Button = %VsyncButton
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var back_button: Button = %BackButton
@onready var reset_button: Button = %ResetButton
@onready var apply_button: Button = %ApplyButton
@onready var dialog = %MenuDialog

var _resolutions: Array[Vector2i] = []
var _updating_ui: bool = false
var _busy: bool = false
var overlay_mode: bool = false


func _ready() -> void:
	gameplay_cat.pressed.connect(_show_page.bind("gameplay"))
	audio_cat.pressed.connect(_show_page.bind("audio"))
	video_cat.pressed.connect(_show_page.bind("video"))
	damage_numbers_button.pressed.connect(_toggle_bool.bind("damage_numbers"))
	screen_shake_button.pressed.connect(_toggle_bool.bind("screen_shake"))
	auto_advance_button.pressed.connect(_toggle_bool.bind("auto_advance"))
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	mute_all_button.pressed.connect(_on_mute_pressed)
	fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	vsync_button.pressed.connect(_on_vsync_pressed)
	resolution_option.item_selected.connect(_on_resolution_selected)
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	_populate_resolutions()
	_refresh_ui()
	_show_page("gameplay")
	_wire_focus()
	if visible:
		damage_numbers_button.grab_focus()


func _wire_focus() -> void:
	gameplay_cat.focus_neighbor_right = gameplay_cat.get_path_to(damage_numbers_button)
	audio_cat.focus_neighbor_right = audio_cat.get_path_to(master_slider)
	video_cat.focus_neighbor_right = video_cat.get_path_to(fullscreen_button)
	damage_numbers_button.focus_neighbor_left = damage_numbers_button.get_path_to(gameplay_cat)
	screen_shake_button.focus_neighbor_left = screen_shake_button.get_path_to(gameplay_cat)
	auto_advance_button.focus_neighbor_left = auto_advance_button.get_path_to(gameplay_cat)
	master_slider.focus_neighbor_left = master_slider.get_path_to(audio_cat)
	fullscreen_button.focus_neighbor_left = fullscreen_button.get_path_to(video_cat)
	back_button.focus_neighbor_top = back_button.get_path_to(gameplay_cat)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _busy or dialog.is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _show_page(page: String) -> void:
	gameplay_page.visible = page == "gameplay"
	audio_page.visible = page == "audio"
	video_page.visible = page == "video"
	gameplay_cat.button_pressed = page == "gameplay"
	audio_cat.button_pressed = page == "audio"
	video_cat.button_pressed = page == "video"
	if not visible:
		return
	match page:
		"gameplay":
			damage_numbers_button.grab_focus()
		"audio":
			master_slider.grab_focus()
		"video":
			fullscreen_button.grab_focus()


func _refresh_ui() -> void:
	_updating_ui = true
	_set_toggle(damage_numbers_button, SettingsManager.damage_numbers)
	_set_toggle(screen_shake_button, SettingsManager.screen_shake)
	_set_toggle(auto_advance_button, SettingsManager.auto_advance)
	master_slider.set_value_no_signal(SettingsManager.master_volume)
	music_slider.set_value_no_signal(SettingsManager.music_volume)
	sfx_slider.set_value_no_signal(SettingsManager.sfx_volume)
	_set_percent(master_value, SettingsManager.master_volume)
	_set_percent(music_value, SettingsManager.music_volume)
	_set_percent(sfx_value, SettingsManager.sfx_volume)
	_set_toggle(mute_all_button, SettingsManager.mute_all)
	_set_toggle(fullscreen_button, SettingsManager.fullscreen)
	_set_toggle(vsync_button, SettingsManager.vsync)
	resolution_option.disabled = SettingsManager.fullscreen
	_select_current_resolution()
	_updating_ui = false


func _populate_resolutions() -> void:
	_resolutions = SettingsManager.get_available_resolutions()
	resolution_option.clear()
	for size in _resolutions:
		resolution_option.add_item("%sx%s" % [str(size.x), str(size.y)])
	_select_current_resolution()


func _select_current_resolution() -> void:
	var current := SettingsManager.resolution
	for i in _resolutions.size():
		if _resolutions[i] == current:
			resolution_option.select(i)
			return
	if _resolutions.size() > 0:
		resolution_option.select(0)


func _set_toggle(button: Button, on: bool) -> void:
	button.text = "ON" if on else "OFF"


func _set_percent(label: Label, value: float) -> void:
	label.text = "%s%%" % str(roundi(value * 100.0))


func _toggle_bool(which: String) -> void:
	match which:
		"damage_numbers":
			SettingsManager.set_damage_numbers(not SettingsManager.damage_numbers)
		"screen_shake":
			SettingsManager.set_screen_shake(not SettingsManager.screen_shake)
		"auto_advance":
			SettingsManager.set_auto_advance(not SettingsManager.auto_advance)
	_refresh_ui()


func _on_master_changed(value: float) -> void:
	if _updating_ui:
		return
	SettingsManager.set_master_volume(value)
	_set_percent(master_value, value)


func _on_music_changed(value: float) -> void:
	if _updating_ui:
		return
	SettingsManager.set_music_volume(value)
	_set_percent(music_value, value)


func _on_sfx_changed(value: float) -> void:
	if _updating_ui:
		return
	SettingsManager.set_sfx_volume(value)
	_set_percent(sfx_value, value)


func _on_mute_pressed() -> void:
	SettingsManager.set_mute_all(not SettingsManager.mute_all)
	_refresh_ui()


func _on_fullscreen_pressed() -> void:
	SettingsManager.set_fullscreen(not SettingsManager.fullscreen)
	_refresh_ui()


func _on_vsync_pressed() -> void:
	SettingsManager.set_vsync(not SettingsManager.vsync)
	_refresh_ui()


func _on_resolution_selected(index: int) -> void:
	if _updating_ui or index < 0 or index >= _resolutions.size():
		return
	SettingsManager.set_resolution(_resolutions[index])


func _on_apply_pressed() -> void:
	SettingsManager.save_settings()


func _on_reset_pressed() -> void:
	if _busy:
		return
	dialog.present("RESET SETTINGS?", "Restore every option to its default value.", "CANCEL", "RESET")
	var result: Variant = await dialog.finished
	if result != true:
		return
	SettingsManager.reset_to_defaults()
	_populate_resolutions()
	_refresh_ui()


func _on_back_pressed() -> void:
	if _busy:
		return
	if not SettingsManager.is_dirty():
		_go_to_menu()
		return
	dialog.present("SAVE CHANGES?", "Keep the current options before leaving?", "DISCARD", "SAVE")
	var result: Variant = await dialog.finished
	if result == null:
		return
	if result == true:
		SettingsManager.save_settings()
	else:
		SettingsManager.discard_changes()
	_go_to_menu()


func show_as_overlay() -> void:
	overlay_mode = true
	_busy = false
	visible = true
	_refresh_ui()
	_show_page("gameplay")
	damage_numbers_button.grab_focus()


func _go_to_menu() -> void:
	if overlay_mode:
		_busy = false
		overlay_mode = false
		visible = false
		closed.emit()
		return
	_busy = true
	SceneTransition.change_scene(GameInfo.MENU_SCENE)
