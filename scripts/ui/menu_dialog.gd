extends Control

signal finished(accepted: Variant)

@onready var title_label: Label = %Title
@onready var body_label: Label = %Body
@onready var cancel_button: Button = %CancelButton
@onready var confirm_button: Button = %ConfirmButton

var _open: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	cancel_button.pressed.connect(_on_cancel)
	confirm_button.pressed.connect(_on_confirm)


func is_open() -> bool:
	return _open


func present(title: String, body: String, cancel_text: String = "CANCEL", confirm_text: String = "CONFIRM") -> void:
	title_label.text = title
	body_label.text = body
	body_label.visible = not body.is_empty()
	cancel_button.text = cancel_text
	confirm_button.text = confirm_text
	visible = true
	_open = true
	cancel_button.grab_focus()


func close() -> void:
	visible = false
	_open = false


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		_dismiss()
		get_viewport().set_input_as_handled()


func _on_cancel() -> void:
	close()
	finished.emit(false)


func _on_confirm() -> void:
	close()
	finished.emit(true)


func _dismiss() -> void:
	close()
	finished.emit(null)
