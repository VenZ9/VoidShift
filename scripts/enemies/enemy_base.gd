# enemy_base.gd
# VOIDSHIFT - Base Modular Enemy Class
class_name EnemyBase
extends CharacterBody2D

@export var max_health: float = 40.0
@export var move_speed: float = 90.0
@export var detection_range: float = 280.0
@export var attack_range: float = 160.0
@export var affected_by_gravity: bool = true

var target_player: CharacterBody2D
var knockback_velocity: Vector2 = Vector2.ZERO
var is_stunned: bool = false
var _stun_timer: float = 0.0
var damage_flash_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

func _ready() -> void:
	add_to_group("enemies")
	EventBus.enemy_spawned.emit(self)
	
	if health_component:
		health_component.max_health = max_health
		health_component.current_health = max_health
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)
		
	if hurtbox_component:
		hurtbox_component.team = Constants.CombatTeam.ENEMY
		hurtbox_component.health_component = health_component
		hurtbox_component.owner_entity = self
		
	EventBus.gravity_changed.connect(_on_gravity_changed)
	_find_player()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _physics_process(delta: float) -> void:
	damage_flash_time = maxf(0.0, damage_flash_time - delta)
	if damage_flash_time > 0.0:
		queue_redraw()
	if _stun_timer > 0.0:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			is_stunned = false
			
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		
	if is_stunned:
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	else:
		process_ai(delta)
		
	# Apply gravity influence
	if affected_by_gravity and not is_on_floor():
		velocity += GravityManager.gravity_vector * 60.0 * delta
		
	# Apply knockback
	if knockback_velocity.length_squared() > 10.0:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		
	move_and_slide()

func process_ai(_delta: float) -> void:
	# Virtual method to be overridden by child enemies
	pass

func stun(duration: float) -> void:
	is_stunned = true
	_stun_timer = maxf(_stun_timer, duration)

func _on_gravity_changed(_new_dir: int, _old_dir: int, _vec: Vector2, angle_rad: float) -> void:
	# Enemies are briefly destabilized when gravity shifts
	stun(0.35)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "rotation", angle_rad, 0.3)

func _on_damaged(amount: float, knockback: Vector2) -> void:
	knockback_velocity = knockback
	damage_flash_time = 0.14
	queue_redraw()
	EventBus.enemy_damaged.emit(self, amount, health_component.current_health)
	
	# Damage flash
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.1, 0.1, 1.0), 0.06)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _on_died() -> void:
	EventBus.enemy_died.emit(self, global_position)
	queue_free()
