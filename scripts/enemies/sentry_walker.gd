extends EnemyBase
class_name SentryWalker

@export var projectile_scene: PackedScene
@export var shield_arc_degrees := 105.0
var _shot_timer := 1.2
var wall_normal := Vector2.DOWN
var shield_flash := 0.0

func _ready() -> void:
	max_health = 110.0
	super._ready()
	if health_component:
		health_component.max_health = max_health
		health_component.current_health = max_health
	queue_redraw()

func process_ai(delta: float) -> void:
	if not is_instance_valid(target_player):
		return
	var tangent := Vector2(-GravityManager.gravity_vector.y, GravityManager.gravity_vector.x)
	var to_player := target_player.global_position - global_position
	if to_player.length() < detection_range:
		var along := to_player.dot(tangent)
		velocity = tangent * signf(along) * move_speed * 0.55
		_shot_timer -= delta
		if _shot_timer <= 0.0:
			_shot_timer = 2.0
			_fire(to_player.normalized())
	else:
		velocity = tangent * sin(Time.get_ticks_msec() * 0.001) * move_speed * 0.35
	shield_flash = maxf(0.0, shield_flash - delta)

func _fire(direction: Vector2) -> void:
	if not projectile_scene:
		return
	for spread in [-0.12, 0.12]:
		var projectile := projectile_scene.instantiate() as Projectile
		projectile.global_position = global_position + direction * 20.0
		projectile.direction = direction.rotated(spread)
		projectile.team = Constants.CombatTeam.ENEMY
		get_parent().add_child(projectile)
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("laser_shoot", -5.0, 0.65)

func _on_gravity_changed(new_dir: int, old_dir: int, vec: Vector2, angle_rad: float) -> void:
	wall_normal = -vec
	super._on_gravity_changed(new_dir, old_dir, vec, angle_rad)
	velocity = wall_normal * move_speed * 1.4
	queue_redraw()

func get_damage_scale(hit_from_dir: Vector2) -> float:
	# Gravity-aligned frontal shield: hits arriving from the shielded arc are
	# reduced instead of healing damage back after it was applied.
	if hit_from_dir.length_squared() > 0.0 and hit_from_dir.dot(wall_normal) > cos(deg_to_rad(shield_arc_degrees * 0.5)):
		return 0.28
	return 1.0

func _on_damaged(amount: float, knockback: Vector2) -> void:
	if amount > 0.0 and knockback.length_squared() > 0.0:
		var hit_dir := -knockback.normalized()
		if hit_dir.dot(wall_normal) > cos(deg_to_rad(shield_arc_degrees * 0.5)):
			shield_flash = 0.18
	var flash_on_shield := shield_flash > 0.0 or damage_flash_time > 0.0
	if not flash_on_shield:
		queue_redraw()
	super._on_damaged(amount, knockback)

func _draw() -> void:
	var frame_color := Color.WHITE if damage_flash_time > 0.0 else Color("344a60")
	draw_rect(Rect2(-15, -13, 30, 26), frame_color, true)
	draw_rect(Rect2(-15, -13, 30, 26), Color("9db8c8"), false, 2.0)
	draw_rect(Rect2(-8, -7, 16, 14), Color("b88040"), true)
	draw_rect(Rect2(-5, -3, 10, 6), Color("ffca62"), true)
	var shield_center := wall_normal.angle()
	draw_arc(Vector2.ZERO, 23.0, shield_center - deg_to_rad(shield_arc_degrees * 0.5), shield_center + deg_to_rad(shield_arc_degrees * 0.5), 16, Color("80ecff") if shield_flash <= 0 else Color.WHITE, 4.0)
