extends PanelContainer

const NumberUtil := preload("res://scripts/number_util.gd")

@onready var slap_level_label: Label = %SlapLevelLabel
@onready var slap_cost_label: Label = %SlapCostLabel
@onready var slap_buy_button: Button = %SlapBuyButton
@onready var regen_level_label: Label = %RegenLevelLabel
@onready var regen_cost_label: Label = %RegenCostLabel
@onready var regen_buy_button: Button = %RegenBuyButton
@onready var assistant_cost_label: Label = %AssistantCostLabel
@onready var assistant_buy_button: Button = %AssistantBuyButton
@onready var warrior_count_label: Label = %WarriorCountLabel
@onready var warrior_dps_label: Label = %WarriorDpsLabel
@onready var warrior_cost_label: Label = %WarriorCostLabel
@onready var warrior_buy_button: Button = %WarriorBuyButton
@onready var pillow_level_label: Label = %PillowLevelLabel
@onready var pillow_cost_label: Label = %PillowCostLabel
@onready var pillow_buy_button: Button = %PillowBuyButton


func _ready() -> void:
	GameManager.gold_changed.connect(_on_economy_changed)
	GameManager.upgrades_changed.connect(_refresh)
	slap_buy_button.pressed.connect(_on_slap_buy)
	regen_buy_button.pressed.connect(_on_regen_buy)
	assistant_buy_button.pressed.connect(_on_assistant_buy)
	warrior_buy_button.pressed.connect(_on_warrior_buy)
	pillow_buy_button.pressed.connect(_on_pillow_buy)
	_refresh()


func _on_economy_changed(_gold: float) -> void:
	_refresh()


func _on_slap_buy() -> void:
	GameManager.buy_damage_upgrade()


func _on_regen_buy() -> void:
	GameManager.buy_hp_regen_upgrade()


func _on_assistant_buy() -> void:
	GameManager.buy_auto_attack()


func _on_warrior_buy() -> void:
	GameManager.buy_warrior()


func _on_pillow_buy() -> void:
	GameManager.buy_pillow()


func _refresh() -> void:
	var slap_cost := GameManager.get_damage_upgrade_cost()
	slap_level_label.text = "Level: %s" % NumberUtil.format(float(GameManager.damage_level))
	slap_cost_label.text = "Cost: %s Gold" % NumberUtil.format(slap_cost)
	slap_buy_button.disabled = GameManager.gold < slap_cost

	var regen_cost := GameManager.get_hp_regen_upgrade_cost()
	regen_level_label.text = "Level: %s  |  %s HP/s" % [
		NumberUtil.format(float(GameManager.hp_regen_level)),
		NumberUtil.format_int(GameManager.get_hero_hp_regen()),
	]
	regen_cost_label.text = "Cost: %s Gold" % NumberUtil.format(regen_cost)
	regen_buy_button.disabled = GameManager.gold < regen_cost

	if GameManager.auto_attack_unlocked:
		assistant_cost_label.text = "Owned"
		assistant_buy_button.text = "OWNED"
		assistant_buy_button.disabled = true
	else:
		assistant_cost_label.text = "Cost: %s Gold" % NumberUtil.format(GameManager.get_auto_attack_cost())
		assistant_buy_button.text = "BUY"
		assistant_buy_button.disabled = GameManager.gold < GameManager.get_auto_attack_cost()

	var warrior_cost := GameManager.get_warrior_cost()
	warrior_count_label.text = "Lazy Squires: %s" % NumberUtil.format(float(GameManager.get_helper_level("squire")))
	warrior_dps_label.text = "Total DPS: %s" % NumberUtil.format_int(GameManager.get_warrior_dps())
	warrior_cost_label.text = "Cost: %s Gold" % NumberUtil.format(warrior_cost)
	warrior_buy_button.disabled = GameManager.gold < warrior_cost

	var pillow_cost := GameManager.get_pillow_cost()
	pillow_level_label.text = "Level: %s  |  %s" % [NumberUtil.format(float(GameManager.pillow_level)), NumberUtil.format_mult(GameManager.get_lazy_power())]
	pillow_cost_label.text = "Cost: %s Gold" % NumberUtil.format(pillow_cost)
	pillow_buy_button.disabled = GameManager.gold < pillow_cost
