extends Button

const HOVER_SCALE := 1.04

var _tween: Tween
var _hovered: bool = false


func _ready() -> void:
	resized.connect(_update_pivot)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	focus_entered.connect(_set_hovered.bind(true))
	focus_exited.connect(_set_hovered.bind(false))
	pressed.connect(_on_pressed)
	_update_pivot()


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _set_hovered(value: bool) -> void:
	_hovered = value
	_animate()


func _animate() -> void:
	if disabled:
		scale = Vector2.ONE
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * (HOVER_SCALE if _hovered else 1.0), 0.12)


func _on_pressed() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play"):
		audio.play("button_click")
