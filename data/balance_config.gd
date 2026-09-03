extends Resource
class_name BalanceConfig

@export var enemy_hp_scaling: float = 1.15
@export var gold_scaling: float = 1.15
@export var upgrade_cost_scaling: float = 1.15
@export var dps_scaling: float = 1.0
@export var prestige_scaling: float = 1.0
@export var crit_chance: float = 0.05
@export var crit_damage: float = 2.0

@export var attack_cooldown: float = 0.5
@export var auto_attack_interval: float = 1.0
@export var helper_tick_interval: float = 1.0
@export var combo_timeout: float = 3.0

@export var warrior_dps: float = 5.0
@export var damage_upgrade_base_cost: float = 10.0
@export var hp_regen_upgrade_base_cost: float = 50.0
@export var hp_regen_per_level: float = 1.0
@export var auto_attack_cost: float = 100.0
@export var warrior_base_cost: float = 500.0
@export var pillow_base_cost: float = 75.0
@export var pillow_lazy_power: float = 0.05

@export var boss_hp_mult: float = 5.0
@export var boss_gold_mult: float = 3.0
@export var world_boss_hp_mult: float = 12.0
@export var world_boss_gold_mult: float = 8.0

@export var autosave_interval: float = 30.0

@export var hero_max_comfort: float = 100.0
@export var comfort_regen: float = 2.0
@export var sleep_resist_mult: float = 0.5
@export var sleep_hits_to_wake: int = 8
@export var retaliate_damage: float = 8.0

@export var event_chance: float = 0.08
@export var event_cooldown: float = 40.0

@export var prestige_unlock_stage: int = 51

@export var enemy_spawn_delay: float = 0.75
@export var hero_max_hp: float = 100.0
@export var hero_hp_regen: float = 0.0
@export var hero_recovery_time: float = 3.0
@export var death_checkpoint_interval: int = 25
