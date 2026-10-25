# hurtbox_component.gd
# VOIDSHIFT - Modular Hurtbox Component receiving hits from Hitboxes
class_name HurtboxComponent
extends Area2D

@export var team: int = Constants.CombatTeam.PLAYER
@export var health_component: HealthComponent
@export var owner_entity: CharacterBody2D

signal hit_received(damage: float, from_team: int)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		var hitbox = area as HitboxComponent
		# Do not damage same team
		if hitbox.team == team:
			return
			
		var knockback_dir = Vector2.ZERO
		if hitbox.damage_source and owner_entity:
			knockback_dir = (owner_entity.global_position - hitbox.damage_source.global_position).normalized()
		elif hitbox is Node2D and owner_entity:
			knockback_dir = (owner_entity.global_position - hitbox.global_position).normalized()
			
		var final_knockback = knockback_dir * hitbox.knockback_force
		# Incoming direction (from victim toward the hit origin) for directional defense.
		var hit_from_dir: Vector2 = -knockback_dir
		
		var damage_scale := 1.0
		if owner_entity and owner_entity.has_method("get_damage_scale"):
			damage_scale = owner_entity.call("get_damage_scale", hit_from_dir)
		
		if health_component:
			var hit_success = health_component.take_damage(hitbox.damage, final_knockback, false, damage_scale)
			if hit_success:
				hit_received.emit(hitbox.damage, hitbox.team)
				if has_node("/root/AudioManager"):
					AudioManager.play_sfx("hit", 0.0, randf_range(0.9, 1.1))
