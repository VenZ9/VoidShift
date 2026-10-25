# virtual_joystick.gd
# VOIDSHIFT - Virtual Analog Joystick for Mobile Landscape Traversal
class_name VirtualJoystick
extends Control

@export var max_drag_radius: float = 64.0
@export var deadzone: float = 0.15

var is_pressed: bool = false
var touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var current_output: Vector2 = Vector2.ZERO

@onready var tip_sprite: Sprite2D = $TipSprite

func _ready() -> void:
	joystick_center = size * 0.5
	if tip_sprite:
		tip_sprite.position = joystick_center

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch = event as InputEventScreenTouch
		if touch.pressed and touch_index == -1:
			touch_index = touch.index
			is_pressed = true
			_update_joystick(touch.position)
		elif not touch.pressed and touch.index == touch_index:
			_release_joystick()
			
	elif event is InputEventScreenDrag:
		var drag = event as InputEventScreenDrag
		if drag.index == touch_index:
			_update_joystick(drag.position)
			
	# Mouse fallback for editor / desktop testing
	elif event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and touch_index == -1:
				touch_index = 999
				is_pressed = true
				_update_joystick(mb.position)
			elif not mb.pressed and touch_index == 999:
				_release_joystick()
				
	elif event is InputEventMouseMotion and touch_index == 999:
		_update_joystick((event as InputEventMouseMotion).position)

func _update_joystick(touch_pos: Vector2) -> void:
	var delta = touch_pos - joystick_center
	var dist = delta.length()
	
	if dist > max_drag_radius:
		delta = delta.normalized() * max_drag_radius
		
	if tip_sprite:
		tip_sprite.position = joystick_center + delta
		
	var norm = delta / max_drag_radius
	if norm.length() < deadzone:
		current_output = Vector2.ZERO
	else:
		current_output = norm
		
	_feed_input_actions(current_output)

func _release_joystick() -> void:
	is_pressed = false
	touch_index = -1
	current_output = Vector2.ZERO
	if tip_sprite:
		tip_sprite.position = joystick_center
	_feed_input_actions(Vector2.ZERO)

func _feed_input_actions(output: Vector2) -> void:
	_set_action_strength("move_left", maxf(0.0, -output.x))
	_set_action_strength("move_right", maxf(0.0, output.x))
	_set_action_strength("move_up", maxf(0.0, -output.y))
	_set_action_strength("move_down", maxf(0.0, output.y))

func _set_action_strength(action: String, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength > 0.05:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)
