# grav_crate.gd
# VOIDSHIFT - Gravity Responsive Heavy Cargo Crate
class_name GravCrate
extends CharacterBody2D

@export var mass_factor: float = 1.0
@export var damage_threshold_speed: float = 180.0
@export var crushing_damage: float = 30.0

var gravity_velocity: Vector2 = Vector2.ZERO
var _last_velocity: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: HitboxComponent = $HitboxComponent

func _ready() -> void:
	add_to_group("props")
	EventBus.gravity_changed.connect(_on_gravity_changed)
	if hitbox:
		hitbox.team = Constants.CombatTeam.ENVIRONMENT
		hitbox.damage = crushing_damage
		hitbox.damage_source = self

func _physics_process(delta: float) -> void:
	# Accelerate in current gravity direction
	var target_grav_vel = GravityManager.gravity_vector * (Constants.GRAVITY_FORCE * mass_factor)
	gravity_velocity = gravity_velocity.move_toward(target_grav_vel, 800.0 * delta)
	
	velocity = gravity_velocity
	_last_velocity = velocity
	
	move_and_slide()
	
	# If collided with wall or entity, stop gravity acceleration in that axis
	if is_on_wall() or is_on_floor() or is_on_ceiling():
		# Check if moving fast enough to trigger a thud/crush
		if _last_velocity.length() > damage_threshold_speed:
			EventBus.camera_shake_requested.emit(4.0, 0.2)
			if has_node("/root/AudioManager"):
				AudioManager.play_sfx("hit", -4.0, 0.6)
		gravity_velocity = Vector2.ZERO

func _on_gravity_changed(_new_dir: int, _old_dir: int, _vec: Vector2, angle_rad: float) -> void:
	# Reset velocity towards new direction
	gravity_velocity = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "rotation", angle_rad, 0.35)
