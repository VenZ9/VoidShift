# projectile.gd
# VOIDSHIFT - Directed Plasma Projectile
class_name Projectile
extends Area2D

@export var speed: float = 480.0
@export var damage: float = 20.0
@export var lifetime: float = 1.8
@export var team: int = Constants.CombatTeam.PLAYER
@export var affected_by_gravity: bool = false
@export var gravity_influence: float = 120.0

var direction: Vector2 = Vector2.RIGHT
var velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var homing_target: Node2D
var homing_strength: float = 0.0

@onready var hitbox: HitboxComponent = $HitboxComponent

func _ready() -> void:
	if hitbox:
		hitbox.damage = damage
		hitbox.team = team
		hitbox.damage_source = self
	
	velocity = direction.normalized() * speed
	rotation = velocity.angle()
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
		
	if affected_by_gravity:
		# Projectiles can slightly curve with current gravity vector
		velocity += GravityManager.gravity_vector * gravity_influence * delta
		rotation = velocity.angle()
	if is_instance_valid(homing_target) and homing_strength > 0.0:
		var desired := (homing_target.global_position - global_position).normalized() * speed
		velocity = velocity.move_toward(desired, homing_strength * delta)
		rotation = velocity.angle()
		
	global_position += velocity * delta

func _on_body_entered(body: Node) -> void:
	# Collided with world walls or solid obstacles
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent and (area as HurtboxComponent).team != team:
		queue_free()
