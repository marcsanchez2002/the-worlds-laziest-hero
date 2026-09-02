extends CanvasLayer

var _rect: ColorRect
var _busy: bool = false


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	add_child(_rect)


func is_busy() -> bool:
	return _busy


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_out := create_tween()
	fade_out.tween_property(_rect, "color:a", 1.0, 0.22)
	await fade_out.finished
	get_tree().change_scene_to_file(path)
	var fade_in := create_tween()
	fade_in.tween_property(_rect, "color:a", 0.0, 0.22)
	await fade_in.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
