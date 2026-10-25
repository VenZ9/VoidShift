# gravity_manager.gd
# VOIDSHIFT - Core Gravitational Rotation & State Manager
extends Node

# Current state
var current_direction: int = Constants.GravityDirection.DOWN
var gravity_vector: Vector2 = Constants.GRAVITY_VECTORS[Constants.GravityDirection.DOWN]
var gravity_angle: float = 0.0 # Radians

# Traversal & physics parameters
var gravity_magnitude: float = Constants.GRAVITY_FORCE
var shift_cooldown_time: float = Constants.GRAVITY_SHIFT_COOLDOWN
var _cooldown_remaining: float = 0.0

# Stats for current run
var total_shifts_performed: int = 0

func _ready() -> void:
	EventBus.gravity_shift_requested.connect(_on_shift_requested)

func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta

func can_shift() -> bool:
	return _cooldown_remaining <= 0.0

func shift_clockwise() -> bool:
	return _perform_shift(1)

func shift_counter_clockwise() -> bool:
	return _perform_shift(-1)

func shift_invert() -> bool:
	return _perform_shift(2)

func shift_to(target_dir: int) -> bool:
	if target_dir < 0 or target_dir > 3:
		return false
	if target_dir == current_direction or not can_shift():
		return false
	var old_dir = current_direction
	current_direction = target_dir
	_apply_gravity_change(old_dir)
	return true

func _perform_shift(step: int) -> bool:
	if not can_shift():
		return false
	var old_dir = current_direction
	current_direction = (current_direction + step + 4) % 4
	_apply_gravity_change(old_dir)
	return true

func _apply_gravity_change(old_dir: int) -> void:
	_cooldown_remaining = shift_cooldown_time
	total_shifts_performed += 1
	gravity_vector = Constants.GRAVITY_VECTORS[current_direction]
	gravity_angle = Constants.GRAVITY_ANGLES[current_direction]
	
	# Audio feedback
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("grav_shift", 0.0, 1.0 + randf_range(-0.05, 0.05))
	
	# Camera shake feedback
	EventBus.camera_shake_requested.emit(5.0, 0.25)
	
	# Notify listeners
	EventBus.gravity_changed.emit(current_direction, old_dir, gravity_vector, gravity_angle)

func reset_gravity() -> void:
	var old_dir = current_direction
	current_direction = Constants.GravityDirection.DOWN
	gravity_vector = Constants.GRAVITY_VECTORS[Constants.GravityDirection.DOWN]
	gravity_angle = 0.0
	_cooldown_remaining = 0.0
	if old_dir != current_direction:
		EventBus.gravity_changed.emit(current_direction, old_dir, gravity_vector, gravity_angle)

func _on_shift_requested(direction_step: int) -> void:
	# Player-initiated shifts cost RIG energy and respect upgrade discounts.
	# Direct API calls (boss gravity surges, tests) never drain player energy.
	var players := _active_players()
	var cost := get_player_shift_cost()
	if not players.is_empty() and cost > 0.0:
		var affordable := false
		for player in players:
			if player.current_energy >= cost:
				affordable = true
				break
		if not affordable:
			EventBus.ui_notification_requested.emit("RIG ENERGY LOW // SHIFT OFFLINE", Color("ffb66c"))
			return
	var shifted := _perform_shift(direction_step)
	if shifted and not players.is_empty() and cost > 0.0:
		for player in players:
			player.current_energy = maxf(0.0, player.current_energy - cost)
			EventBus.player_energy_changed.emit(player.current_energy, player.max_energy)

const ENERGY_EFFICIENCY_DISCOUNT := 0.65

func get_player_shift_cost() -> float:
	var stack: int = LootManager.get_upgrade_stack("energy_efficiency")
	return Constants.GRAVITY_SHIFT_COST * pow(ENERGY_EFFICIENCY_DISCOUNT, stack)

func _active_players() -> Array:
	var players := []
	if is_instance_valid(get_tree()):
		for node in get_tree().get_nodes_in_group("player"):
			if node is Player and node.health_component.current_health > 0.0:
				players.append(node)
	return players

func get_direction_name(dir: int = -1) -> String:
	var d = current_direction if dir == -1 else dir
	match d:
		Constants.GravityDirection.DOWN:
			return "DOWN (Floor)"
		Constants.GravityDirection.RIGHT:
			return "RIGHT (East Wall)"
		Constants.GravityDirection.UP:
			return "UP (Ceiling)"
		Constants.GravityDirection.LEFT:
			return "LEFT (West Wall)"
	return "UNKNOWN"
