# player.gd
# VOIDSHIFT - Player Omni-Grav RIG Suit Controller
class_name Player
extends CharacterBody2D

@export var move_speed: float = Constants.PLAYER_BASE_SPEED
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0

# Energy & Dash stats
@export var max_energy: float = Constants.PLAYER_BASE_ENERGY
var current_energy: float = Constants.PLAYER_BASE_ENERGY
var energy_regen_rate: float = Constants.ENERGY_REGEN_RATE

# Dash state
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.DOWN

# Weapon & Combat
@export var projectile_scene: PackedScene
var fire_cooldown: float = 0.25
var _fire_timer: float = 0.0
var facing_direction: Vector2 = Vector2.DOWN

# Knockback
var knockback_velocity: Vector2 = Vector2.ZERO

# Child node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var muzzle_marker: Marker2D = $MuzzleMarker

var _rotation_tween: Tween

func _ready() -> void:
	EventBus.player_spawned.emit(self)
	
	health_component.health_changed.connect(_on_health_changed)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	
	EventBus.gravity_changed.connect(_on_gravity_changed)
	
	_apply_permanent_stats()
	_apply_run_upgrades()
	
	# Deferred so UI nodes that join this frame connect before first readout.
	_emit_initial_readouts.call_deferred()

func _apply_permanent_stats() -> void:
	var stats: Dictionary = SaveManager.profile_data.get("permanent_stats", {})
	var bonus_hp: float = stats.get("bonus_max_hp", 0.0)
	if bonus_hp > 0.0:
		health_component.set_max_health(health_component.max_health + bonus_hp)
	if move_speed < Constants.PLAYER_BASE_SPEED:
		move_speed = Constants.PLAYER_BASE_SPEED

func _apply_run_upgrades() -> void:
	# Kinetic Plating is a run-self-contained max health boost.
	var plating_stack: int = LootManager.get_upgrade_stack("kinetic_plating")
	if plating_stack > 0:
		health_component.set_max_health(health_component.max_health + 25.0 * plating_stack, true)

func _emit_initial_readouts() -> void:
	EventBus.player_health_changed.emit(health_component.current_health, health_component.max_health)
	EventBus.player_energy_changed.emit(current_energy, max_energy)

func _physics_process(delta: float) -> void:
	if health_component.current_health <= 0.0:
		return
		
	_process_energy(delta)
	_process_weapons(delta)
	
	if is_dashing:
		_process_dash(delta)
	else:
		_process_movement(delta)
		_process_dash_input()
		
	# Apply knockback decay
	if knockback_velocity.length_squared() > 10.0:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, friction * 1.5 * delta)
		
	move_and_slide()

func _process_energy(delta: float) -> void:
	if current_energy < max_energy:
		var bonus_regen = SaveManager.profile_data.get("permanent_stats", {}).get("bonus_energy_regen", 0.0)
		var rate = energy_regen_rate + bonus_regen
		current_energy = minf(max_energy, current_energy + rate * delta)
		EventBus.player_energy_changed.emit(current_energy, max_energy)

func _process_movement(delta: float) -> void:
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Preserve analog magnitude (virtual stick); normalize only saturated vectors.
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		facing_direction = input_vector
		velocity = velocity.move_toward(input_vector * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	# Gravitational magnetic traction assist
	# Subtle pull in current gravity direction if stationary
	if input_vector == Vector2.ZERO and not is_on_wall():
		velocity += GravityManager.gravity_vector * 40.0 * delta

func _process_dash_input() -> void:
	if Input.is_action_just_pressed("dash"):
		perform_dash()

func perform_dash() -> bool:
	if is_dashing or current_energy < Constants.PLAYER_DASH_COST:
		return false
		
	current_energy -= Constants.PLAYER_DASH_COST
	EventBus.player_energy_changed.emit(current_energy, max_energy)
	
	is_dashing = true
	dash_timer = Constants.PLAYER_DASH_DURATION
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		dash_direction = input_dir.normalized()
	else:
		dash_direction = facing_direction
		
	velocity = dash_direction * Constants.PLAYER_DASH_SPEED
	health_component.set_invulnerable(Constants.PLAYER_DASH_DURATION + 0.1)
	
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("grav_shift", -6.0, 1.8)
		
	EventBus.player_dashed.emit(dash_direction)
	return true

func _process_dash(delta: float) -> void:
	dash_timer -= delta
	velocity = dash_direction * Constants.PLAYER_DASH_SPEED
	if dash_timer <= 0.0:
		is_dashing = false

func _process_weapons(delta: float) -> void:
	if _fire_timer > 0.0:
		_fire_timer -= delta
		
	if Input.is_action_pressed("fire") and _fire_timer <= 0.0:
		fire_weapon()

func fire_weapon() -> void:
	var rate_mult = 0.7 if LootManager.has_upgrade("rapid_fire") else 1.0
	_fire_timer = fire_cooldown * rate_mult
	
	var spawn_pos = muzzle_marker.global_position if muzzle_marker else global_position
	var aim_dir = facing_direction
	
	# If mouse is in use, can aim towards mouse position
	var mouse_pos = get_global_mouse_position()
	if mouse_pos.distance_squared_to(global_position) > 400.0 and not OS.has_feature("mobile"):
		aim_dir = (mouse_pos - global_position).normalized()
		
	if projectile_scene:
		var proj = projectile_scene.instantiate() as Projectile
		proj.global_position = spawn_pos
		proj.direction = aim_dir
		proj.team = Constants.CombatTeam.PLAYER
		get_parent().add_child(proj)
		
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("laser_shoot", -3.0, randf_range(0.95, 1.05))
		
	EventBus.player_fired_weapon.emit(spawn_pos, aim_dir)
	EventBus.camera_shake_requested.emit(1.5, 0.1)

func _on_gravity_changed(new_dir: int, _old_dir: int, _grav_vector: Vector2, angle_rad: float) -> void:
	# Smoothly orient player sprite towards the new down direction
	if _rotation_tween and _rotation_tween.is_valid():
		_rotation_tween.kill()
		
	_rotation_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_rotation_tween.tween_property(sprite, "rotation", angle_rad, 0.3)
	
	# Check upgrade benefits
	if LootManager.has_upgrade("grav_shield"):
		health_component.set_invulnerable(0.6)
		
	if LootManager.has_upgrade("overcharge_burst"):
		_trigger_overcharge_burst()

func _trigger_overcharge_burst() -> void:
	EventBus.camera_shake_requested.emit(6.0, 0.3)
	# Damage nearby enemies within 120 pixels
	var space = get_world_2d().direct_space_state
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is CharacterBody2D and e.global_position.distance_to(global_position) <= 120.0:
			var hc = e.get_node_or_null("HealthComponent") as HealthComponent
			if hc:
				var push = (e.global_position - global_position).normalized() * 300.0
				hc.take_damage(20.0, push)

func _on_damaged(amount: float, knockback: Vector2) -> void:
	knockback_velocity = knockback
	EventBus.camera_shake_requested.emit(8.0, 0.35)
	
	# Damage flash visual effect
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func _on_health_changed(current: float, maximum: float) -> void:
	EventBus.player_health_changed.emit(current, maximum)

func _on_died() -> void:
	EventBus.camera_shake_requested.emit(15.0, 0.6)
	EventBus.player_died.emit()
	queue_free()
