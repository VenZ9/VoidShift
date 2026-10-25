# loot_manager.gd
# VOIDSHIFT - Upgrade Catalog, Drop Tables & Pickup Spawner
extends Node

const SCRAP_PICKUP_SCENE = "res://scenes/props/scrap_pickup.tscn"
const ENERGY_PICKUP_SCENE = "res://scenes/props/energy_pickup.tscn"

# Roguelite Upgrades Catalog
const UPGRADES: Dictionary = {
	"grav_shield": {
		"name": "Phase Barrier",
		"desc": "Grants 0.6s invulnerability after any gravity shift.",
		"rarity": "rare",
		"cost": 150
	},
	"overcharge_burst": {
		"name": "Kinetic Pulse",
		"desc": "Gravity shifts release a radial shockwave dealing 20 damage.",
		"rarity": "rare",
		"cost": 200
	},
	"energy_efficiency": {
		"name": "Superconductor",
		"desc": "Reduces gravity shift energy cost by 35%.",
		"rarity": "common",
		"cost": 100
	},
	"magnetic_attractor": {
		"name": "Mag-Vortex",
		"desc": "Doubles pickup attraction radius.",
		"rarity": "common",
		"cost": 80
	},
	"rapid_fire": {
		"name": "Overclocked Coils",
		"desc": "Increases firing rate by 30%.",
		"rarity": "uncommon",
		"cost": 120
	},
	"kinetic_plating": {
		"name": "Composite Plating",
		"desc": "Increases Max Health by 25 and restores 25 HP.",
		"rarity": "common",
		"cost": 100
	}
}

# Active upgrades in the current run
var current_run_upgrades: Dictionary = {}

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)

func reset_run_upgrades() -> void:
	current_run_upgrades.clear()

func apply_upgrade(upgrade_id: String) -> bool:
	if not UPGRADES.has(upgrade_id):
		return false
	var count = current_run_upgrades.get(upgrade_id, 0) + 1
	current_run_upgrades[upgrade_id] = count
	EventBus.upgrade_applied.emit(upgrade_id, UPGRADES[upgrade_id])
	return true

func has_upgrade(upgrade_id: String) -> bool:
	return current_run_upgrades.has(upgrade_id)

func get_upgrade_stack(upgrade_id: String) -> int:
	return current_run_upgrades.get(upgrade_id, 0)

func _on_enemy_died(enemy: Node2D, death_pos: Vector2) -> void:
	var parent = enemy.get_parent()
	if parent:
		# 75% chance to drop scrap
		if randf() < 0.75:
			var scrap_amount = randi_range(1, 3)
			spawn_scrap(parent, death_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)), scrap_amount)
		# 40% chance to drop energy
		if randf() < 0.40:
			spawn_energy_cell(parent, death_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 20.0)

func spawn_scrap(parent: Node, spawn_pos: Vector2, value: int = 1) -> Node2D:
	if not ResourceLoader.exists(SCRAP_PICKUP_SCENE):
		return null
	var scene = load(SCRAP_PICKUP_SCENE)
	var instance = scene.instantiate()
	instance.position = spawn_pos
	if instance.has_method("set_value"):
		instance.set_value(value)
	parent.call_deferred("add_child", instance)
	return instance

func spawn_energy_cell(parent: Node, spawn_pos: Vector2, energy_amount: float = 20.0) -> Node2D:
	if not ResourceLoader.exists(ENERGY_PICKUP_SCENE):
		return null
	var scene = load(ENERGY_PICKUP_SCENE)
	var instance = scene.instantiate()
	instance.position = spawn_pos
	if instance.has_method("set_energy_amount"):
		instance.set_energy_amount(energy_amount)
	parent.call_deferred("add_child", instance)
	return instance
