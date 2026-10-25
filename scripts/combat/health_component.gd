# health_component.gd
# VOIDSHIFT - Modular Health & Damage Receiving Component
class_name HealthComponent
extends Node

signal health_changed(current_hp: float, max_hp: float)
signal damaged(amount: float, knockback_vector: Vector2)
signal healed(amount: float)
signal died()

@export var max_health: float = 100.0
var current_health: float = 100.0
var is_invulnerable: bool = false
var _invuln_timer: float = 0.0

func _ready() -> void:
	current_health = max_health

func _process(delta: float) -> void:
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		if _invuln_timer <= 0.0:
			is_invulnerable = false

func take_damage(amount: float, knockback_vector: Vector2 = Vector2.ZERO, ignore_invuln: bool = false, damage_scale: float = 1.0) -> bool:
	if (is_invulnerable and not ignore_invuln) or current_health <= 0.0:
		return false
		
	var scaled_amount: float = amount * clampf(damage_scale, 0.0, 1.0)
	current_health = maxf(0.0, current_health - scaled_amount)
	damaged.emit(scaled_amount, knockback_vector)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0.0:
		died.emit()
	return true

func heal(amount: float) -> void:
	if current_health <= 0.0:
		return
	current_health = minf(max_health, current_health + amount)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

func set_invulnerable(duration: float) -> void:
	is_invulnerable = true
	_invuln_timer = maxf(_invuln_timer, duration)

func set_max_health(new_max: float, heal_difference: bool = true) -> void:
	var diff = new_max - max_health
	max_health = new_max
	if heal_difference and diff > 0:
		current_health += diff
	current_health = clampf(current_health, 0.0, max_health)
	health_changed.emit(current_health, max_health)
