extends EnemyBase
class_name PhaseLurker

@export var projectile_scene: PackedScene
var _phase_timer := 0.8
var _windup := false
var _attack_cooldown := 0.0
var _afterimage := 0.0

func _ready() -> void:
	max_health = 55.0
	move_speed = 145.0
	super._ready()
	if health_component:
		health_component.max_health = max_health
		health_component.current_health = max_health
	queue_redraw()

func process_ai(delta: float) -> void:
	if not is_instance_valid(target_player):
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_afterimage = maxf(0.0, _afterimage - delta)
	_phase_timer -= delta
	var distance := global_position.distance_to(target_player.global_position)
	if _phase_timer <= 0.0 and not _windup and distance < detection_range and _attack_cooldown <= 0.0:
		_windup = true
		_phase_timer = 0.72
		velocity = Vector2.ZERO
		queue_redraw()
	elif _windup and _phase_timer <= 0.0:
		_ambush()
	elif _windup:
		velocity = Vector2.ZERO
	else:
		var tangent := Vector2(-GravityManager.gravity_vector.y, GravityManager.gravity_vector.x)
		velocity = (target_player.global_position - global_position).normalized() * move_speed * 0.45 + tangent * sin(Time.get_ticks_msec() * 0.003) * 35.0

func _ambush() -> void:
	_windup = false
	_attack_cooldown = 2.0
	if is_instance_valid(target_player):
		var gravity_tangent := Vector2(-GravityManager.gravity_vector.y, GravityManager.gravity_vector.x)
		var side := signf((target_player.global_position - global_position).dot(gravity_tangent))
		if side == 0.0:
			side = 1.0
		var teleport_pos := target_player.global_position - gravity_tangent * side * 96.0
		if _is_safe_position(teleport_pos):
			global_position = teleport_pos
		# If the teleport is blocked, close distance the ordinary way instead.
		var toward := (target_player.global_position - global_position).normalized()
		velocity = toward * move_speed * 2.0
		if global_position.distance_to(target_player.global_position) < 110.0:
			var health := target_player.get_node_or_null("HealthComponent") as HealthComponent
			if health:
				health.take_damage(14.0, toward * 170.0)
	_afterimage = 0.24
	_phase_timer = 0.55
	queue_redraw()

func _is_safe_position(pos: Vector2) -> bool:
	# A teleport destination must be free of static world geometry.
	var space := get_world_2d().direct_space_state
	if not space:
		return false
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = Constants.LAYER_WORLD
	var hits = space.intersect_point(query)
	if not hits.is_empty():
		return false
	# Also reject positions outside the enclosing drive if one exists.
	var room := get_parent()
	if room and room is RoomBase:
		var local = room.global_position
		var bounds: Vector2 = (room as RoomBase).room_dimensions
		if pos.x < local.x + 40.0 or pos.x > local.x + bounds.x - 40.0:
			return false
		if pos.y < local.y + 40.0 or pos.y > local.y + bounds.y - 40.0:
			return false
	return true

func _on_gravity_changed(new_dir: int, old_dir: int, vec: Vector2, angle_rad: float) -> void:
	# Flux bursts give the lurker a readable short teleport opportunity.
	_phase_timer = minf(_phase_timer, 0.35)
	super._on_gravity_changed(new_dir, old_dir, vec, angle_rad)

func _draw() -> void:
	var alpha := 0.35 if _windup else (0.25 if _afterimage > 0 else 0.9)
	var body_color := Color(0.35, 0.18, 0.65, alpha)
	if damage_flash_time > 0.0:
		body_color = Color(0.95, 0.85, 1.0, alpha)
	draw_rect(Rect2(-12, -14, 24, 28), body_color, true)
	draw_rect(Rect2(-12, -14, 24, 28), Color(0.6, 0.45, 1.0, alpha), false, 2.0)
	draw_rect(Rect2(-7, -3, 14, 5), Color(0.7, 1.0, 1.0, alpha), true)
	if _windup:
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 24, Color("da74ff"), 3.0)
