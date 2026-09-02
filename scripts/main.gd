extends Node


func _ready() -> void:
	GameManager.bind_world($World/CombatArea)
	GameManager.begin_session()
