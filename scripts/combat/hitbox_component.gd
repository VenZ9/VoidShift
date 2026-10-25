# hitbox_component.gd
# VOIDSHIFT - Modular Hitbox Component dealing damage to Hurtboxes
class_name HitboxComponent
extends Area2D

@export var damage: float = 15.0
@export var knockback_force: float = 220.0
@export var team: int = Constants.CombatTeam.PLAYER

# Optional reference to owner node dealing the hit
var damage_source: Node2D

func _ready() -> void:
	# Preserve the scene-configured collision layer: area-vs-area damage routing
	# needs the hitbox layer to match opposing hurtbox masks.
	monitoring = true
