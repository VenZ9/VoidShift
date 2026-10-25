# touch_controls.gd
# VOIDSHIFT - Touch Input Overlay for Android Landscape Gameplay
class_name TouchControls
extends CanvasLayer

@onready var joystick: VirtualJoystick = $Control/JoystickContainer/VirtualJoystick
@onready var btn_shift_cw: TextureButton = $Control/ButtonsContainer/BtnShiftCW
@onready var btn_shift_ccw: TextureButton = $Control/ButtonsContainer/BtnShiftCCW
@onready var btn_fire: TextureButton = $Control/ButtonsContainer/BtnFire
@onready var btn_dash: TextureButton = $Control/ButtonsContainer/BtnDash
@onready var btn_pause: TextureButton = $Control/TopBar/BtnPause

func _ready() -> void:
	layer = 10
	_apply_settings_opacity()
	
	# Connect buttons
	if btn_shift_cw:
		btn_shift_cw.pressed.connect(_on_shift_cw_pressed)
	if btn_shift_ccw:
		btn_shift_ccw.pressed.connect(_on_shift_ccw_pressed)
	if btn_fire:
		btn_fire.button_down.connect(func(): Input.action_press("fire"))
		btn_fire.button_up.connect(func(): Input.action_release("fire"))
	if btn_dash:
		btn_dash.button_down.connect(func(): Input.action_press("dash"))
		btn_dash.button_up.connect(func(): Input.action_release("dash"))
	if btn_pause:
		btn_pause.pressed.connect(_on_pause_pressed)

func _apply_settings_opacity() -> void:
	var opacity = SaveManager.settings_data.get("touch_controls_opacity", 0.85)
	var root_ctrl = get_node_or_null("Control")
	if root_ctrl:
		root_ctrl.modulate.a = opacity

func _on_shift_cw_pressed() -> void:
	EventBus.gravity_shift_requested.emit(1)

func _on_shift_ccw_pressed() -> void:
	EventBus.gravity_shift_requested.emit(-1)

func _on_pause_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("ui_click")
	GameManager.toggle_pause()
