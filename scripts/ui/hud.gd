# hud.gd
# VOIDSHIFT - In-Game Tactical HUD Display
class_name HUD
extends CanvasLayer
const AEGIS_SCRIPT := preload("res://scripts/enemies/aegis_core.gd")

@onready var health_bar: ProgressBar = $MarginContainer/TopLeft/VBox/HealthBar
@onready var health_label: Label = $MarginContainer/TopLeft/VBox/HealthBar/HealthLabel
@onready var energy_bar: ProgressBar = $MarginContainer/TopLeft/VBox/EnergyBar
@onready var energy_label: Label = $MarginContainer/TopLeft/VBox/EnergyBar/EnergyLabel
@onready var scrap_label: Label = $MarginContainer/TopLeft/VBox/ScrapContainer/ScrapLabel
@onready var grav_label: Label = $MarginContainer/TopCenter/GravContainer/GravLabel
@onready var grav_dial: TextureRect = $MarginContainer/TopCenter/GravContainer/CenterDial/GravDial
@onready var sector_label: Label = $MarginContainer/TopRight/SectorLabel

var _compass_tween: Tween
var boss_bar: ProgressBar
var boss_label: Label
var notice_label: Label
var _notice_timer := 0.0

func _ready() -> void:
	layer = 5
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_energy_changed.connect(_on_energy_changed)
	EventBus.scrap_collected.connect(_on_scrap_collected)
	EventBus.gravity_changed.connect(_on_gravity_changed)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.ui_notification_requested.connect(_on_notification)
	boss_label = Label.new()
	boss_label.text = "AEGIS SECURITY CORE"
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.add_theme_color_override("font_color", Color("9cefff"))
	boss_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_label.position = Vector2(-150, 104)
	boss_label.size = Vector2(300, 22)
	boss_bar = ProgressBar.new()
	boss_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar.position = Vector2(-190, 128)
	boss_bar.size = Vector2(380, 15)
	boss_bar.max_value = 720.0
	boss_bar.visible = false
	boss_label.visible = false
	add_child(boss_bar)
	add_child(boss_label)
	notice_label = Label.new()
	notice_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notice_label.position = Vector2(-300, 160)
	notice_label.size = Vector2(600, 34)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.add_theme_font_size_override("font_size", 19)
	notice_label.visible = false
	add_child(notice_label)
	
	# Initial readouts
	_update_scrap(SaveManager.profile_data.get("available_scrap", 0))
	_update_gravity_display(GravityManager.current_direction, GravityManager.gravity_angle)

func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
	if health_label:
		health_label.text = "HP %d / %d" % [int(current), int(maximum)]

func _on_energy_changed(current: float, maximum: float) -> void:
	if energy_bar:
		energy_bar.max_value = maximum
		energy_bar.value = current
	if energy_label:
		energy_label.text = "RIG %d / %d" % [int(current), int(maximum)]

func _on_scrap_collected(_amount: int, total_scrap: int) -> void:
	_update_scrap(total_scrap)

func _update_scrap(total: int) -> void:
	if scrap_label:
		scrap_label.text = "SCRAP: %d" % total

func _on_gravity_changed(new_dir: int, _old_dir: int, _vec: Vector2, angle_rad: float) -> void:
	_update_gravity_display(new_dir, angle_rad)

func _update_gravity_display(direction: int, angle_rad: float) -> void:
	if grav_label:
		grav_label.text = "GRAV: " + GravityManager.get_direction_name(direction).to_upper()
		
	if grav_dial:
		if _compass_tween and _compass_tween.is_valid():
			_compass_tween.kill()
		_compass_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_compass_tween.tween_property(grav_dial, "rotation", angle_rad, 0.3)

func _process(delta: float) -> void:
	if _notice_timer > 0.0:
		_notice_timer -= delta
		if _notice_timer <= 0.0 and notice_label:
			notice_label.visible = false

func _on_enemy_damaged(enemy: Node2D, _damage: float, current_hp: float) -> void:
	if enemy.get_script() == AEGIS_SCRIPT:
		var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
		boss_bar.max_value = health.max_health if health else 1.0
		boss_bar.value = current_hp
		boss_bar.visible = true
		boss_label.visible = true

func _on_enemy_spawned(enemy: Node2D) -> void:
	if enemy.get_script() == AEGIS_SCRIPT:
		var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
		boss_bar.max_value = health.max_health if health else 1.0
		boss_bar.value = health.current_health if health else 1.0
		boss_bar.visible = true
		boss_label.visible = true

func _on_enemy_died(enemy: Node2D, _position: Vector2) -> void:
	if enemy.get_script() == AEGIS_SCRIPT:
		boss_bar.visible = false
		boss_label.visible = false

func _on_notification(message: String, color: Color) -> void:
	if not notice_label:
		return
	notice_label.text = message
	notice_label.add_theme_color_override("font_color", color)
	notice_label.visible = true
	_notice_timer = 2.0
