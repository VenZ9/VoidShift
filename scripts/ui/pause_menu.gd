# pause_menu.gd
# VOIDSHIFT - In-Game Pause & Configuration Overlay
class_name PauseMenu
extends CanvasLayer

@onready var panel: Control = $PanelContainer
@onready var btn_resume: Button = $PanelContainer/VBox/BtnResume
@onready var btn_restart: Button = $PanelContainer/VBox/BtnRestart
@onready var btn_main_menu: Button = $PanelContainer/VBox/BtnMainMenu

@onready var slider_master: HSlider = $PanelContainer/VBox/Settings/MasterSlider
@onready var slider_sfx: HSlider = $PanelContainer/VBox/Settings/SFXSlider
@onready var slider_ambient: HSlider = $PanelContainer/VBox/Settings/AmbientSlider
@onready var check_camera_rotate: CheckBox = $PanelContainer/VBox/Settings/CheckCameraRotate

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	visible = false
	
	EventBus.game_paused.connect(_on_game_paused)
	
	if btn_resume:
		btn_resume.pressed.connect(_on_resume_pressed)
	if btn_restart:
		btn_restart.pressed.connect(_on_restart_pressed)
	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_main_menu_pressed)
		
	if slider_master:
		slider_master.value = SaveManager.settings_data.get("master_volume", 1.0)
		slider_master.value_changed.connect(func(v): 
			SaveManager.settings_data["master_volume"] = v
			AudioManager.set_master_volume(v)
		)
	if slider_sfx:
		slider_sfx.value = SaveManager.settings_data.get("sfx_volume", 0.9)
		slider_sfx.value_changed.connect(func(v):
			SaveManager.settings_data["sfx_volume"] = v
			AudioManager.set_sfx_volume(v)
		)
	if slider_ambient:
		slider_ambient.value = SaveManager.settings_data.get("ambient_volume", 0.6)
		slider_ambient.value_changed.connect(func(v):
			SaveManager.settings_data["ambient_volume"] = v
			AudioManager.set_ambient_volume(v)
		)
	if check_camera_rotate:
		check_camera_rotate.button_pressed = SaveManager.settings_data.get("camera_rotate_with_gravity", true)
		check_camera_rotate.toggled.connect(func(p):
			SaveManager.settings_data["camera_rotate_with_gravity"] = p
		)

func _on_game_paused(is_paused: bool) -> void:
	visible = is_paused
	if not is_paused:
		SaveManager.save_settings()

func _on_resume_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("ui_click")
	GameManager.set_paused(false)

func _on_restart_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("ui_click")
	GameManager.set_paused(false)
	GameManager.start_new_run()

func _on_main_menu_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("ui_click")
	SaveManager.save_settings()
	GameManager.return_to_main_menu()
