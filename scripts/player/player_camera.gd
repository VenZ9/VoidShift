# player_camera.gd
# VOIDSHIFT - Dynamic Roguelite Camera with Gravity Orientation & Shake
class_name PlayerCamera
extends Camera2D

@export var follow_speed: float = 8.0
@export var lookahead_distance: float = 30.0
@export var target_node: Node2D

var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0
var _target_rotation: float = 0.0
var _rotation_tween: Tween

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed
	
	EventBus.camera_shake_requested.connect(start_shake)
	EventBus.gravity_changed.connect(_on_gravity_changed)
	EventBus.player_spawned.connect(func(p): target_node = p)

func _process(delta: float) -> void:
	if target_node and is_instance_valid(target_node):
		var target_pos = target_node.global_position
		if target_node is CharacterBody2D:
			target_pos += (target_node as CharacterBody2D).velocity.normalized() * lookahead_distance
		global_position = global_position.lerp(target_pos, follow_speed * delta)
		
	# Process screen shake
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var damping = _shake_timer / maxf(0.001, _shake_timer + delta)
		var mult = SaveManager.settings_data.get("screen_shake_intensity", 1.0)
		offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity) * mult,
			randf_range(-_shake_intensity, _shake_intensity) * mult
		)
		_shake_intensity *= damping
		if _shake_timer <= 0.0:
			offset = Vector2.ZERO

func start_shake(intensity: float, duration: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_timer = maxf(_shake_timer, duration)

func _on_gravity_changed(_new_dir: int, _old_dir: int, _vec: Vector2, angle_rad: float) -> void:
	var should_rotate = SaveManager.settings_data.get("camera_rotate_with_gravity", true)
	if not should_rotate:
		return
		
	# Smoothly align camera with player's down orientation
	if _rotation_tween and _rotation_tween.is_valid():
		_rotation_tween.kill()
		
	_target_rotation = angle_rad
	_rotation_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_rotation_tween.tween_property(self, "rotation", _target_rotation, 0.4)
