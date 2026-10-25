extends EnemyBase
class_name AegisCore

enum Phase { SHIELD, GRAVITY, MELTDOWN }
@export var projectile_scene: PackedScene
var phase: Phase = Phase.SHIELD
var damage_window := false
var _attack_timer := 1.1
var _telegraph_timer := 0.0
var _attack_kind := 0
var _beam_angle := 0.0
var _beam_active := false
var _beam_damage_timer := 0.0
var _phase_two_shift_timer := 3.0
var _phase_three_volley_timer := 2.0

func _ready() -> void:
	max_health = 720.0
	move_speed = 0.0
	affected_by_gravity = false
	super._ready()
	if health_component:
		health_component.max_health = max_health
		health_component.current_health = max_health
	queue_redraw()

func process_ai(delta: float) -> void:
	if not is_instance_valid(target_player):
		return
	_attack_timer -= delta
	_telegraph_timer = maxf(0.0, _telegraph_timer - delta)
	_beam_damage_timer = maxf(0.0, _beam_damage_timer - delta)
	if phase == Phase.GRAVITY:
		_phase_two_shift_timer -= delta
		if _phase_two_shift_timer <= 0.0:
			_phase_two_shift_timer = 3.4
			GravityManager.shift_clockwise()
	if phase == Phase.MELTDOWN:
		_phase_three_volley_timer -= delta
		if _phase_three_volley_timer <= 0.0:
			_phase_three_volley_timer = 2.4
			_fire_homing_drones()
	if _attack_timer <= 0.0 and _telegraph_timer <= 0.0 and not _beam_active:
		_start_attack()
	if _beam_active:
		_update_beam(delta)
	queue_redraw()

func _start_attack() -> void:
	_attack_timer = 3.4 if phase == Phase.SHIELD else 2.8
	_attack_kind = randi_range(0, 1)
	_telegraph_timer = 0.85
	_beam_angle = (target_player.global_position - global_position).angle()
	_beam_active = true
	damage_window = false
	EventBus.ui_notification_requested.emit("AEGIS WEAPON LOCK // MOVE", Color("ffb66c"))
	queue_redraw()

func _update_beam(delta: float) -> void:
	if _telegraph_timer > 0.0:
		# The tracking line is visible first; rotation speed is limited for fair dodging.
		var target_angle := (target_player.global_position - global_position).angle()
		_beam_angle = rotate_toward(_beam_angle, target_angle, 0.8 * delta)
		return
	if _attack_kind == 0:
		var from_boss := target_player.global_position - global_position
		var along := from_boss.dot(Vector2.RIGHT.rotated(_beam_angle))
		var side := absf(from_boss.cross(Vector2.RIGHT.rotated(_beam_angle)))
		if along > 32.0 and along < 520.0 and side < 18.0 and _beam_damage_timer == 0.0:
			var player_health := target_player.get_node_or_null("HealthComponent") as HealthComponent
			if player_health:
				player_health.take_damage(11.0, Vector2.RIGHT.rotated(_beam_angle) * 100.0)
			_beam_damage_timer = 0.45
	else:
		_fire_burst()
	_beam_active = false
	damage_window = true
	_attack_timer = 1.0
	queue_redraw()

func _fire_burst() -> void:
	if not projectile_scene:
		return
	var count := 6 if phase == Phase.SHIELD else 8
	for i in count:
		var p := projectile_scene.instantiate() as Projectile
		p.global_position = global_position
		p.direction = Vector2.RIGHT.rotated(TAU * float(i) / count)
		p.speed = 275.0
		p.damage = 9.0
		p.team = Constants.CombatTeam.ENEMY
		get_parent().add_child(p)
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("laser_shoot", -3.0, 0.55)

func _fire_homing_drones() -> void:
	if not projectile_scene:
		return
	for i in 3:
		var p := projectile_scene.instantiate() as Projectile
		p.global_position = global_position + Vector2.RIGHT.rotated(TAU * i / 3.0) * 38.0
		p.direction = (target_player.global_position - p.global_position).normalized().rotated((i - 1) * 0.16)
		p.speed = 230.0
		p.damage = 8.0
		p.team = Constants.CombatTeam.ENEMY
		p.homing_target = target_player
		p.homing_strength = 210.0
		get_parent().add_child(p)

func _on_damaged(amount: float, knockback: Vector2) -> void:
	if not damage_window:
		health_component.heal(amount)
		return
	super._on_damaged(amount, knockback)
	var hp_ratio := health_component.current_health / health_component.max_health
	if phase == Phase.SHIELD and hp_ratio <= 0.66:
		phase = Phase.GRAVITY
		EventBus.ui_notification_requested.emit("AEGIS PHASE 2 // GRAVITY SURGE", Color("62eaff"))
	elif phase == Phase.GRAVITY and hp_ratio <= 0.33:
		phase = Phase.MELTDOWN
		EventBus.ui_notification_requested.emit("CORE UNSTABLE // MICRO-DRONES", Color("ff705c"))
	queue_redraw()

func _on_died() -> void:
	EventBus.enemy_died.emit(self, global_position)
	EventBus.sector_completed.emit(GameManager.current_sector)
	GameManager.change_state(Constants.GameState.VICTORY)
	SaveManager.record_run_completion(true, GameManager.current_sector)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 50.0, Color("fff3e8") if damage_flash_time > 0.0 else Color("132b42"))
	draw_arc(Vector2.ZERO, 51.0, 0.0, TAU, 48, Color("3feaff"), 4.0)
	draw_circle(Vector2.ZERO, 27.0, Color("f27455") if phase == Phase.MELTDOWN else Color("5ba9dc"))
	draw_circle(Vector2.ZERO, 12.0, Color("fff1b0"))
	for i in 4:
		var a := Time.get_ticks_msec() * 0.0005 + i * PI * 0.5
		var pos := Vector2.RIGHT.rotated(a) * 66.0
		draw_rect(Rect2(pos - Vector2(10, 16), Vector2(20, 32)), Color("8ef5ff") if damage_window else Color("71889d"), true)
	if _beam_active:
		var end := Vector2.RIGHT.rotated(_beam_angle) * 510.0
		draw_line(Vector2.ZERO, end, Color(1.0, 0.28, 0.18, 0.32) if _telegraph_timer > 0.0 else Color("ff3e3e"), 3.0 if _telegraph_timer > 0.0 else 8.0)
