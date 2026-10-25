# sentry_drone.gd
# VOIDSHIFT - Sentry Drone Enemy (Ranged Hovering Sentry)
class_name SentryDrone
extends EnemyBase

@export var projectile_scene: PackedScene
@export var shoot_interval: float = 1.4

var _shoot_timer: float = 0.0

@onready var muzzle_marker: Marker2D = $MuzzleMarker

func process_ai(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	var dir_to_player = (target_player.global_position - global_position).normalized()
	
	if dist <= detection_range:
		# Keep optimal combat distance (130 - 180 px)
		if dist > attack_range:
			velocity = velocity.move_toward(dir_to_player * move_speed, 400.0 * delta)
		elif dist < attack_range * 0.7:
			velocity = velocity.move_toward(-dir_to_player * move_speed * 0.8, 400.0 * delta)
		else:
			# Circle/strafe around player
			var strafe_dir = Vector2(-dir_to_player.y, dir_to_player.x)
			velocity = velocity.move_toward(strafe_dir * (move_speed * 0.5), 300.0 * delta)
			
		# Shoot attack
		_shoot_timer += delta
		if _shoot_timer >= shoot_interval:
			_shoot_timer = 0.0
			_fire_at_player(dir_to_player)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)

func _fire_at_player(dir: Vector2) -> void:
	if not projectile_scene:
		return
	var proj = projectile_scene.instantiate() as Projectile
	var spawn_pos = muzzle_marker.global_position if muzzle_marker else global_position
	proj.global_position = spawn_pos
	proj.direction = dir
	proj.team = Constants.CombatTeam.ENEMY
	get_parent().add_child(proj)
	
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("laser_shoot", -6.0, 0.75)
