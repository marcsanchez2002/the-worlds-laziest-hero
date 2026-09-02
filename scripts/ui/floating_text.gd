extends Label


func setup(text_value: String, color: Color, big: bool) -> void:
	text = text_value
	modulate = color
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	position = Vector2(randf_range(-40.0, 40.0), -40.0)
	z_index = 20
	if big:
		add_theme_font_size_override("font_size", 34)
		position.y = -70.0
	else:
		add_theme_font_size_override("font_size", 22)
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 70.0, 0.7)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.7)
	tween.finished.connect(queue_free)
